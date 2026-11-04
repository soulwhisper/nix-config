#!/usr/bin/env python3
"""Consumer-level real-crypto tests. Run: python3 -m unittest discover -s pkgs/root-ca -p 'test_*.py' -v"""

import fcntl
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("root_ca.py").resolve()


class RootAuthorityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fixture = tempfile.TemporaryDirectory(prefix="root-ca-fixture-", dir="/tmp")
        cls.base = Path(cls.fixture.name)
        cls.password = cls.base / "password"
        cls.password.write_bytes(os.urandom(32).hex().encode() + b"\n")
        cls.password.chmod(0o600)
        cls.seed = cls.base / "seed"
        cls.invoke(
            cls.seed,
            "init",
            "--subject",
            "/CN=Isolated Test Root",
            "--bits",
            "2048",
            "--days",
            "10",
            "--passphrase-file",
            cls.password,
        )
        cls.identity = cls.base / "age-identity"
        subprocess.run(
            ["age-keygen", "-o", str(cls.identity)], check=True, capture_output=True
        )
        cls.recipient = subprocess.run(
            ["age-keygen", "-y", str(cls.identity)],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()

    @classmethod
    def tearDownClass(cls):
        cls.fixture.cleanup()

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="root-ca-case-", dir="/tmp")
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name)
        self.state = self.home / "authority"
        shutil.copytree(self.seed, self.state, symlinks=True)
        self.state.chmod(0o700)

    @staticmethod
    def invoke(state, *arguments, ok=True, authority=None, env=None):
        command = [sys.executable, str(SCRIPT), "--state", str(state)]
        if authority:
            command += ["--authority", authority]
        result = subprocess.run(
            [*command, *map(str, arguments)], capture_output=True, text=True, env=env
        )
        if ok and result.returncode:
            raise AssertionError(f"root-ca failed: {result.stderr}")
        if not ok and not result.returncode:
            raise AssertionError("root-ca unexpectedly succeeded")
        return result

    def cli(self, *arguments, **kwargs):
        return self.invoke(self.state, *arguments, **kwargs)

    def status(self):
        return json.loads(self.cli("status").stdout)

    def csr(self, name):
        key, request = self.home / f"{name}.key", self.home / f"{name}.csr"
        subprocess.run(
            [
                "openssl",
                "genpkey",
                "-algorithm",
                "RSA",
                "-pkeyopt",
                "rsa_keygen_bits:2048",
                "-aes-256-cbc",
                "-pass",
                f"file:{self.password}",
                "-out",
                str(key),
            ],
            check=True,
            capture_output=True,
        )
        subprocess.run(
            [
                "openssl",
                "req",
                "-new",
                "-sha256",
                "-key",
                str(key),
                "-passin",
                f"file:{self.password}",
                "-subj",
                f"/CN={name}",
                "-addext",
                "basicConstraints=critical,CA:TRUE,pathlen:5",
                "-addext",
                "subjectAltName=DNS:unapproved.invalid",
                "-out",
                str(request),
            ],
            check=True,
            capture_output=True,
        )
        return request

    def sign(self, name, replaces=None):
        request = self.csr(name)
        fields = ["--csr", request, "--days", "3", "--change", f"approve {name}"]
        if replaces:
            fields += ["--replaces", replaces]
        plan = json.loads(self.cli("intermediate", "plan", *fields).stdout)
        output = self.home / f"{name}.crt"
        result = json.loads(
            self.cli(
                "intermediate",
                "rotate" if replaces else "sign",
                *fields,
                "--approval",
                plan["approval"],
                "--output",
                output,
                "--passphrase-file",
                self.password,
            ).stdout
        )
        return result["serial"], output

    def revoke_fields(self, value):
        return [
            "--serial",
            value,
            "--reason",
            "superseded",
            "--change",
            "retire replaced intermediate",
        ]

    def backup(self, name="snapshot.age"):
        output = self.home / name
        self.cli("backup", "--recipient", self.recipient, "--output", output)
        return output

    def restore_fields(self, backup, minimum=None):
        status = self.status()
        return [
            "restore",
            "--input",
            backup,
            "--identity",
            self.identity,
            "--expected-sha256",
            hashlib.sha256(backup.read_bytes()).hexdigest(),
            "--minimum-generation",
            minimum or status["generation"],
            "--expected-fingerprint",
            status["active"],
        ]

    def test_complete_crypto_lifecycle(self):
        first, first_cert = self.sign("intermediate-one")
        second, second_cert = self.sign("intermediate-two", replaces=first)
        self.assertNotEqual(first, second)
        self.cli("verify", "--certificate", first_cert)
        self.cli("verify", "--certificate", second_cert)
        text = subprocess.run(
            ["openssl", "x509", "-in", str(second_cert), "-text", "-noout"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout
        self.assertIn("CA:TRUE, pathlen:0", text)
        self.assertNotIn("unapproved.invalid", text)
        fields = self.revoke_fields(first)
        plan = json.loads(self.cli("intermediate", "revoke", *fields, "--plan").stdout)
        self.cli(
            "intermediate",
            "revoke",
            *fields,
            "--approval",
            plan["approval"],
            "--passphrase-file",
            self.password,
        )
        self.cli("crl", "verify")
        public = self.home / "public"
        self.cli("export", "--output", public, "--serial", second)
        self.assertEqual(
            (public / "intermediate.crt").read_bytes(), second_cert.read_bytes()
        )
        self.assertFalse(list(public.rglob("*.key")))
        self.cli(
            "verify",
            "--certificate",
            first_cert,
            "--crl",
            public / "root.crl",
            ok=False,
        )
        self.cli("verify", "--certificate", second_cert, "--crl", public / "root.crl")
        snapshot = self.backup()
        self.assertNotIn(self.password.read_bytes().strip(), snapshot.read_bytes())
        self.assertNotIn(b"BEGIN ENCRYPTED PRIVATE KEY", snapshot.read_bytes())
        restored = self.home / "restored"
        before = self.status()
        self.invoke(restored, *self.restore_fields(snapshot))
        self.assertEqual(
            self.invoke(restored, "fingerprint").stdout.strip(), before["active"]
        )
        self.assertEqual(
            json.loads(self.invoke(restored, "status").stdout)["generation"],
            before["generation"] + 1,
        )
        self.invoke(restored, "crl", "issue", "--passphrase-file", self.password)
        self.invoke(restored, "verify", "--certificate", second_cert)
        old = before["active"]
        rollover = [
            "rollover",
            "--subject",
            "/CN=Successor Test Root",
            "--bits",
            "2048",
            "--days",
            "10",
            "--change",
            "root rollover",
        ]
        plan = json.loads(self.cli(*rollover, "--plan").stdout)
        new = self.cli(
            *rollover,
            "--approval",
            plan["approval"],
            "--passphrase-file",
            self.password,
        ).stdout.strip()
        self.assertNotEqual(old, new)
        overlap = self.home / "overlap"
        self.cli("export", "--output", overlap)
        self.assertEqual(len(list((overlap / "roots").glob("*.crt"))), 2)
        self.cli("crl", "issue", "--passphrase-file", self.password, authority=old)
        retire = ["retire", "--change", "external clients migrated"]
        plan = json.loads(self.cli(*retire, "--plan", authority=old).stdout)
        self.cli(*retire, "--approval", plan["approval"], authority=old, ok=False)
        self.cli(
            *retire,
            "--approval",
            plan["approval"],
            "--acknowledge-external-trust-removal",
            authority=old,
        )
        self.cli(
            "crl", "issue", "--passphrase-file", self.password, authority=old, ok=False
        )
        final = self.home / "final-public"
        self.cli("export", "--output", final)
        self.assertEqual(len(list((final / "roots").glob("*.crt"))), 1)
        self.assertEqual(self.status()["authorities"][old]["status"], "retired")
        final_snapshot = self.backup("retired.age")
        final_restore = self.home / "retired-restore"
        self.invoke(final_restore, *self.restore_fields(final_snapshot))
        self.assertEqual(
            json.loads(self.invoke(final_restore, "status").stdout)["authorities"][old][
                "status"
            ],
            "retired",
        )

    def test_certificate_only_import_preserves_identity_and_cannot_sign(self):
        identity = self.status()["active"]
        cert = self.state / "current" / "authorities" / identity / "root_ca.crt"
        missing_ack = self.home / "unacknowledged"
        self.invoke(missing_ack, "import", "--certificate", cert, ok=False)
        imported = self.home / "imported"
        self.invoke(
            imported,
            "import",
            "--certificate",
            cert,
            "--acknowledge-incomplete-history",
        )
        self.assertEqual(self.invoke(imported, "fingerprint").stdout.strip(), identity)
        status = json.loads(self.invoke(imported, "status").stdout)
        self.assertEqual(status["authorities"][identity]["history"], "incomplete")
        self.assertFalse(status["signingKeysPresent"][identity])
        request = self.csr("cert-only")
        fields = [
            "--csr",
            request,
            "--days",
            "2",
            "--change",
            "certificate-only cannot sign",
        ]
        plan = json.loads(self.invoke(imported, "intermediate", "plan", *fields).stdout)
        output = self.home / "must-not-exist.crt"
        failure = self.invoke(
            imported,
            "intermediate",
            "sign",
            *fields,
            "--approval",
            plan["approval"],
            "--output",
            output,
            "--passphrase-file",
            self.password,
            ok=False,
        )
        self.assertIn("certificate-only", failure.stderr)
        self.assertFalse(output.exists())
        self.assertEqual(
            json.loads(self.invoke(imported, "status").stdout)["generation"], 1
        )

    def test_complete_history_import_and_existing_state_guard(self):
        value, cert = self.sign("history")
        identity = self.status()["active"]
        history = self.state / "current" / "authorities" / identity
        target = self.home / "imported-history"
        fields = [
            "import",
            "--certificate",
            history / "root_ca.crt",
            "--key",
            history / "root.key",
            "--history-directory",
            history,
            "--passphrase-file",
            self.password,
        ]
        self.invoke(target, *fields)
        self.invoke(target, "verify", "--certificate", cert)
        self.assertEqual(self.invoke(target, "fingerprint").stdout.strip(), identity)
        self.assertEqual(
            json.loads(self.invoke(target, "status").stdout)["authorities"][identity][
                "history"
            ],
            "complete",
        )
        self.invoke(target, *fields, ok=False)
        self.invoke(target, "verify", "--certificate", cert)

    def test_wrong_password_and_changed_approval_leave_no_commit(self):
        request = self.csr("failures")
        fields = ["--csr", request, "--days", "2", "--change", "approved change"]
        token = json.loads(self.cli("intermediate", "plan", *fields).stdout)["approval"]
        before = self.status()
        wrong = self.home / "wrong-password"
        wrong.write_bytes(os.urandom(32).hex().encode())
        wrong.chmod(0o600)
        output = self.home / "not-issued.crt"
        self.cli(
            "intermediate",
            "sign",
            *fields,
            "--approval",
            token,
            "--output",
            output,
            "--passphrase-file",
            wrong,
            ok=False,
        )
        self.assertEqual(before, self.status())
        self.assertFalse(output.exists())
        self.cli(
            "intermediate",
            "sign",
            *fields,
            "--approval",
            "0" * 64,
            "--output",
            output,
            "--passphrase-file",
            self.password,
            ok=False,
        )
        self.assertEqual(before, self.status())
        self.assertFalse(output.exists())
        wrong.chmod(0o644)
        self.cli(
            "intermediate",
            "sign",
            *fields,
            "--approval",
            token,
            "--output",
            output,
            "--passphrase-file",
            wrong,
            ok=False,
        )
        self.assertEqual(before, self.status())

    def test_generation_bound_approval_and_output_no_clobber(self):
        request = self.csr("stale-plan")
        fields = ["--csr", request, "--days", "2", "--change", "approved once"]
        token = json.loads(self.cli("intermediate", "plan", *fields).stdout)["approval"]
        self.cli("crl", "issue", "--passphrase-file", self.password)
        before = self.status()
        output = self.home / "not-issued.crt"
        self.cli(
            "intermediate",
            "sign",
            *fields,
            "--approval",
            token,
            "--output",
            output,
            "--passphrase-file",
            self.password,
            ok=False,
        )
        self.assertEqual(before, self.status())
        token = json.loads(self.cli("intermediate", "plan", *fields).stdout)["approval"]
        output.write_bytes(b"existing public material")
        self.cli(
            "intermediate",
            "sign",
            *fields,
            "--approval",
            token,
            "--output",
            output,
            "--passphrase-file",
            self.password,
            ok=False,
        )
        self.assertEqual(output.read_bytes(), b"existing public material")
        self.assertEqual(before, self.status())

    def test_revoke_crl_crypto_failure_rolls_back_both(self):
        value, cert = self.sign("atomic-revocation")
        self.cli("crl", "issue", "--passphrase-file", self.password)
        before = self.status()
        root = before["active"]
        old_crl = (
            self.state / "current" / "authorities" / root / "root.crl"
        ).read_bytes()
        fields = self.revoke_fields(value)
        token = json.loads(
            self.cli("intermediate", "revoke", *fields, "--plan").stdout
        )["approval"]
        binaries = self.home / "bin"
        binaries.mkdir()
        wrapper = binaries / "openssl"
        wrapper.write_text(
            '#!/bin/sh\nfor arg do [ "$arg" != "-gencrl" ] || exit 41; done\nexec "$REAL_OPENSSL" "$@"\n'
        )
        wrapper.chmod(0o700)
        env = dict(
            os.environ,
            REAL_OPENSSL=shutil.which("openssl"),
            PATH=f"{binaries}:{os.environ['PATH']}",
        )
        self.cli(
            "intermediate",
            "revoke",
            *fields,
            "--approval",
            token,
            "--passphrase-file",
            self.password,
            env=env,
            ok=False,
        )
        self.assertEqual(before, self.status())
        self.assertEqual(
            old_crl,
            (self.state / "current" / "authorities" / root / "root.crl").read_bytes(),
        )
        public = self.home / "after-failure"
        self.cli("export", "--output", public)
        self.cli("verify", "--certificate", cert, "--crl", public / "root.crl")

    def test_exclusive_lock_rejects_second_writer(self):
        before = self.status()
        with (self.state / "lock").open("rb") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            result = self.cli(
                "crl", "issue", "--passphrase-file", self.password, ok=False
            )
            self.assertIn("locked", result.stderr)
        self.assertEqual(before, self.status())

    def test_stale_restore_and_wrong_fingerprint_rejected_without_destination(self):
        snapshot = self.backup()
        old_generation = self.status()["generation"]
        self.cli("crl", "issue", "--passphrase-file", self.password)
        destination = self.home / "stale"
        self.invoke(destination, *self.restore_fields(snapshot), ok=False)
        self.assertFalse(destination.exists())
        self.invoke(
            destination,
            *self.restore_fields(snapshot, minimum=old_generation),
            "--reference-state",
            self.state,
            ok=False,
        )
        self.assertFalse(destination.exists())
        fields = self.restore_fields(snapshot, minimum=old_generation)
        fields[-1] = "0" * 64
        self.invoke(destination, *fields, ok=False)
        self.assertFalse(destination.exists())

    def test_ciphertext_tamper_and_existing_destination_preserved(self):
        snapshot = self.backup()
        snapshot.write_bytes(snapshot.read_bytes()[:-16] + os.urandom(16))
        target = self.home / "bad-restore"
        self.invoke(target, *self.restore_fields(snapshot), ok=False)
        self.assertFalse(target.exists())
        valid = self.backup("valid.age")
        target.mkdir(mode=0o700)
        sentinel = target / "lock"
        sentinel.write_bytes(b"user-owned uninitialized state")
        self.invoke(target, *self.restore_fields(valid), ok=False)
        self.assertEqual(sentinel.read_bytes(), b"user-owned uninitialized state")

    def test_valid_recipient_ciphertext_replacement_is_rejected(self):
        trusted = self.backup()
        fields = self.restore_fields(trusted)
        replacement = self.backup("different-valid-ciphertext.age")
        fields[fields.index("--input") + 1] = replacement
        target = self.home / "substituted-backup"
        result = self.invoke(target, *fields, ok=False)
        self.assertIn("trusted SHA-256", result.stderr)
        self.assertFalse(target.exists())

    def test_bad_csr_and_repo_state_rejected(self):
        bad = self.home / "bad.csr"
        bad.write_bytes(b"not a certificate request")
        before = self.status()
        self.cli(
            "intermediate",
            "plan",
            "--csr",
            bad,
            "--change",
            "invalid request",
            ok=False,
        )
        self.assertEqual(before, self.status())
        checkout = self.home / "checkout"
        checkout.mkdir()
        (checkout / ".git").write_text("gitdir: unrelated")
        result = self.invoke(
            checkout / "private",
            "init",
            "--subject",
            "/CN=Forbidden",
            "--bits",
            "2048",
            "--passphrase-file",
            self.password,
            ok=False,
        )
        self.assertIn("Git checkout", result.stderr)
        self.assertFalse((checkout / "private").exists())

    def test_final_root_retirement_disables_publication_without_claiming_erasure(self):
        identity = self.status()["active"]
        fields = ["retire", "--change", "close final authority"]
        token = json.loads(self.cli(*fields, "--plan").stdout)["approval"]
        self.cli(*fields, "--approval", token, "--acknowledge-external-trust-removal")
        status = self.status()
        self.assertIsNone(status["active"])
        self.assertTrue(status["signingKeysPresent"][identity])
        self.assertEqual(status["authorities"][identity]["status"], "retired")
        self.cli(
            "crl",
            "issue",
            "--passphrase-file",
            self.password,
            authority=identity,
            ok=False,
        )
        output = self.home / "retired-public"
        self.cli("export", "--output", output, authority=identity, ok=False)
        self.assertFalse(output.exists())

    def test_changed_csr_invalidates_approval(self):
        request = self.csr("approved-request")
        changed = self.csr("different-request")
        fields = ["--csr", request, "--days", "2", "--change", "one request only"]
        token = json.loads(self.cli("intermediate", "plan", *fields).stdout)["approval"]
        request.write_bytes(changed.read_bytes())
        before = self.status()
        output = self.home / "changed-csr.crt"
        self.cli(
            "intermediate",
            "sign",
            *fields,
            "--approval",
            token,
            "--output",
            output,
            "--passphrase-file",
            self.password,
            ok=False,
        )
        self.assertEqual(before, self.status())
        self.assertFalse(output.exists())

    def test_passphrase_fd_supports_repeated_crypto_calls(self):
        destination = self.home / "fd-authority"
        with self.password.open("rb") as secret:
            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "--state",
                    str(destination),
                    "init",
                    "--subject",
                    "/CN=FD Test",
                    "--days",
                    "2",
                    "--bits",
                    "2048",
                    "--passphrase-fd",
                    str(secret.fileno()),
                ],
                pass_fds=(secret.fileno(),),
                capture_output=True,
                text=True,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        with self.password.open("rb") as secret:
            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "--state",
                    str(destination),
                    "crl",
                    "issue",
                    "--passphrase-fd",
                    str(secret.fileno()),
                ],
                pass_fds=(secret.fileno(),),
                capture_output=True,
                text=True,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.invoke(destination, "crl", "verify")


if __name__ == "__main__":
    unittest.main()
