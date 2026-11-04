"""Real age/SOPS/X.509 lifecycle tests; never contact a host or activate a system."""

import argparse
import base64
import contextlib
import datetime as dt
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import yaml
from cryptography import x509
from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, ed25519, padding, rsa, utils
from cryptography.x509.oid import NameOID

import controller as c


def quiet(function, args):
    output = io.StringIO()
    with contextlib.redirect_stdout(output):
        result = function(args)
    return result, output.getvalue()


def signing_usage():
    return x509.KeyUsage(False, False, False, False, False, True, True, False, False)


class MaterialLifecycle(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.identity = self.base / "identity"
        c.run(["age-keygen", "--output", self.identity], sensitive=True)
        self.recipient = (
            c.run(["age-keygen", "-y", self.identity], sensitive=True).decode().strip()
        )
        self.environment = patch.dict(
            os.environ, {"SOPS_AGE_KEY_FILE": str(self.identity)}
        )
        self.environment.start()
        self.addCleanup(self.environment.stop)
        self.directory = self.base / "controller"
        quiet(
            c.generate,
            argparse.Namespace(
                directory=str(self.directory),
                common_name="Disposable test intermediate",
                recipient=[self.recipient],
            ),
        )
        self.csr = x509.load_pem_x509_csr(
            (self.directory / "intermediate.csr").read_bytes()
        )
        self.root_key = ec.generate_private_key(ec.SECP384R1())
        subject = x509.Name(
            [x509.NameAttribute(NameOID.COMMON_NAME, "Disposable test root")]
        )
        self.now = dt.datetime.now(dt.timezone.utc)
        self.root = (
            x509.CertificateBuilder()
            .subject_name(subject)
            .issuer_name(subject)
            .public_key(self.root_key.public_key())
            .serial_number(x509.random_serial_number())
            .not_valid_before(self.now - dt.timedelta(days=1))
            .not_valid_after(self.now + dt.timedelta(days=30))
            .add_extension(x509.BasicConstraints(ca=True, path_length=1), critical=True)
            .add_extension(signing_usage(), critical=True)
            .add_extension(
                x509.SubjectKeyIdentifier.from_public_key(self.root_key.public_key()),
                critical=False,
            )
            .add_extension(
                x509.AuthorityKeyIdentifier.from_issuer_public_key(
                    self.root_key.public_key()
                ),
                critical=False,
            )
            .sign(self.root_key, hashes.SHA384())
        )
        self.root_path = self.base / "root.crt"
        self.cert_path = self.base / "intermediate.crt"
        self.root_path.write_bytes(self.root.public_bytes(serialization.Encoding.PEM))
        self.issue()
        self.args = argparse.Namespace(
            directory=str(self.directory),
            certificate=str(self.cert_path),
            root=str(self.root_path),
            root_fingerprint=self.root.fingerprint(hashes.SHA256()).hex(),
            identity=[str(self.identity)],
            recipient=None,
            sops_file=str(self.base / "secrets.sops.yaml"),
        )

    def issue(self, *, public_key=None, path_length=0, expires=None, signer=None):
        cert = (
            x509.CertificateBuilder()
            .subject_name(self.csr.subject)
            .issuer_name(self.root.subject)
            .public_key(public_key or self.csr.public_key())
            .serial_number(x509.random_serial_number())
            .not_valid_before(self.now - dt.timedelta(hours=1))
            .not_valid_after(expires or self.now + dt.timedelta(days=7))
            .add_extension(
                x509.BasicConstraints(ca=True, path_length=path_length), critical=True
            )
            .add_extension(signing_usage(), critical=True)
            .add_extension(
                x509.SubjectKeyIdentifier.from_public_key(
                    public_key or self.csr.public_key()
                ),
                critical=False,
            )
            .add_extension(
                x509.AuthorityKeyIdentifier.from_issuer_public_key(
                    self.root_key.public_key()
                ),
                critical=False,
            )
            .sign(signer or self.root_key, hashes.SHA384())
        )
        self.cert_path.write_bytes(cert.public_bytes(serialization.Encoding.PEM))

    def test_real_key_csr_and_validation(self):
        material, _, cert = c.validate_material(self.args)
        self.assertEqual(cert.subject, self.csr.subject)
        self.assertTrue(self.csr.is_signature_valid)
        self.assertEqual((self.directory.stat().st_mode & 0o777), 0o700)
        for path in self.directory.iterdir():
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
        self.assertEqual(
            set(p.name for p in self.directory.iterdir()),
            {"intermediate.key", "intermediate.csr", "intermediate-password.age"},
        )
        for path in self.directory.iterdir():
            self.assertNotIn(
                material["intermediate-password"].encode(), path.read_bytes()
            )
        self.assertIn("ENCRYPTED PRIVATE KEY", material["intermediate-key"])

    def test_wrong_fingerprint_fails(self):
        self.args.root_fingerprint = "0" * 64
        with self.assertRaisesRegex(c.Refusal, "fingerprint"):
            c.validate_material(self.args)

    def test_wrong_key_fails(self):
        self.issue(public_key=ec.generate_private_key(ec.SECP384R1()).public_key())
        with self.assertRaisesRegex(c.Refusal, "do not match"):
            c.validate_material(self.args)

    def test_subordinate_ca_permission_fails(self):
        self.issue(path_length=1)
        with self.assertRaisesRegex(c.Refusal, "pathlen:0"):
            c.validate_material(self.args)

    def test_expired_intermediate_fails(self):
        self.issue(expires=self.now - dt.timedelta(minutes=10))
        with self.assertRaisesRegex(c.Refusal, "not currently valid"):
            c.validate_material(self.args)

    def test_invalid_signature_fails_without_secret_diagnostics(self):
        self.issue(signer=ec.generate_private_key(ec.SECP384R1()))
        output = io.StringIO()
        with contextlib.redirect_stderr(output):
            result = c.main(
                [
                    "pki-admin",
                    "validate",
                    "--directory",
                    str(self.directory),
                    "--certificate",
                    str(self.cert_path),
                    "--root",
                    str(self.root_path),
                    "--root-fingerprint",
                    self.args.root_fingerprint,
                    "--identity",
                    str(self.identity),
                ]
            )
        self.assertEqual(result, 1)
        self.assertNotIn("Traceback", output.getvalue())
        self.assertNotIn("PRIVATE KEY", output.getvalue())

    def test_atomic_four_field_staging_preserves_secrets_and_two_recipients(self):
        identity2 = self.base / "second-identity"
        c.run(["age-keygen", "--output", identity2], sensitive=True)
        recipient2 = (
            c.run(["age-keygen", "-y", identity2], sensitive=True).decode().strip()
        )
        existing = {
            "unrelated": {
                "token": "test-only-sensitive-value",
                "list": [1, True, "keep"],
            },
            "pki": {"unrelated": "preserve me"},
        }
        encrypted = c.run(
            [
                "sops",
                "--config",
                "/dev/null",
                "--encrypt",
                "--input-type",
                "json",
                "--output-type",
                "yaml",
                "--age",
                self.recipient + "," + recipient2,
                "/dev/stdin",
            ],
            data=c.canonical(existing),
            sensitive=True,
        )
        path = Path(self.args.sops_file)
        path.write_bytes(encrypted)
        _, output = quiet(c.stage, self.args)
        after = path.read_bytes()
        self.assertNotEqual(after, encrypted)
        values = c.sops_decrypt(after)
        self.assertEqual(values["unrelated"], existing["unrelated"])
        self.assertEqual(values["pki"]["unrelated"], "preserve me")
        material, _, _ = c.validate_material(self.args)
        for name, value in material.items():
            self.assertEqual(values["pki"][name], value)
            self.assertNotIn(value, output)
        document = yaml.safe_load(after)
        protected, _ = c.sops_metadata(document)
        self.assertEqual(set(protected), {self.recipient, recipient2})
        for name in material:
            self.assertTrue(document["pki"][name].startswith("ENC[AES256_GCM,"))
        self.assertNotIn(b"test-only-sensitive-value", after)
        self.assertNotIn(b"BEGIN ENCRYPTED PRIVATE KEY", after)
        self.assertFalse(list(self.base.glob(".secrets.sops.yaml.*")))

    def test_new_file_requires_explicit_recipients_and_rejects_existing_rekey(self):
        path = Path(self.args.sops_file)
        with self.assertRaisesRegex(c.Refusal, "recipients"):
            quiet(c.stage, self.args)
        self.assertFalse(path.exists())
        self.args.recipient = [self.recipient]
        quiet(c.stage, self.args)
        before = path.read_bytes()
        with self.assertRaisesRegex(c.Refusal, "NEW"):
            quiet(c.stage, self.args)
        self.assertEqual(path.read_bytes(), before)

    def test_repository_creation_rules_cannot_override_staging(self):
        checkout = self.base / "checkout"
        checkout.mkdir()
        (checkout / ".sops.yaml").write_text(
            "creation_rules:\n  - path_regex: ^never-match$\n    age: "
            + self.recipient
            + "\n"
        )
        self.args.recipient = [self.recipient]
        with contextlib.chdir(checkout):
            quiet(c.stage, self.args)
        encrypted = Path(self.args.sops_file).read_bytes()
        protected, _ = c.sops_metadata(yaml.safe_load(encrypted))
        self.assertEqual(protected, [self.recipient])
        self.assertEqual(
            c.sops_decrypt(encrypted)["pki"]["intermediate-crt"],
            self.cert_path.read_text(),
        )

    def test_unsupported_metadata_is_not_rekeyed(self):
        self.args.recipient = [self.recipient]
        quiet(c.stage, self.args)
        path = Path(self.args.sops_file)
        document = yaml.safe_load(path.read_bytes())
        document["sops"]["key_groups"] = [{"age": []}]
        path.write_text(yaml.safe_dump(document))
        before = path.read_bytes()
        self.args.recipient = None
        with self.assertRaisesRegex(c.Refusal, "metadata"):
            quiet(c.stage, self.args)
        self.assertEqual(path.read_bytes(), before)

    def test_invalid_material_cannot_change_existing_ciphertext(self):
        self.args.recipient = [self.recipient]
        quiet(c.stage, self.args)
        path = Path(self.args.sops_file)
        before = path.read_bytes()
        self.args.recipient = None
        self.args.root_fingerprint = "0" * 64
        with self.assertRaises(c.Refusal):
            quiet(c.stage, self.args)
        self.assertEqual(path.read_bytes(), before)


class DeploymentSafety(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.plan = {
            "schema": 1,
            "repo": str(self.base),
            "host": "test-host",
            "revision": "a" * 40,
            "target": "operator@test-host",
            "system": "/nix/store/" + "a" * 32 + "-nixos-system-new",
            "previous_system": "/nix/store/" + "b" * 32 + "-nixos-system-old",
        }
        self.plan_path = self.base / "plan.json"
        self.plan_path.write_text(json.dumps(self.plan))

    def test_all_mutations_refuse_wrong_or_missing_approval_before_any_execution(self):
        for action in ("copy", "deploy", "activate", "rollback"):
            args = argparse.Namespace(
                action=action, plan=str(self.plan_path), approve=None
            )
            with (
                self.subTest(action=action),
                patch.object(
                    c, "run", side_effect=AssertionError("executed before approval")
                ),
            ):
                with self.assertRaisesRegex(c.Refusal, "approval"):
                    c.deployment_action(args)

    def test_approval_binds_each_material_field_and_action(self):
        approved = c.approval(self.plan)
        self.assertNotEqual(approved, c.approval(self.plan, rollback=True))
        for name in ("revision", "target", "host", "repo", "system", "previous_system"):
            changed = {**self.plan, name: self.plan[name] + "x"}
            self.assertNotEqual(approved, c.approval(changed), name)

    def test_unsafe_targets_and_store_paths_are_rejected_before_execution(self):
        for field, values in {
            "target": [
                "-oStrictHostKeyChecking=no",
                "host;touch /tmp/pwn",
                "host\ncommand",
                "user@host -p22",
                "$(id)",
            ],
            "system": [
                "/tmp/result",
                self.plan["system"] + "/../x",
                "--option",
                self.plan["system"] + ";id",
            ],
        }.items():
            for value in values:
                document = {**self.plan, field: value}
                self.plan_path.write_text(json.dumps(document))
                with (
                    self.subTest(field=field, value=value),
                    patch.object(
                        c, "run", side_effect=AssertionError("unsafe execution")
                    ),
                ):
                    with self.assertRaises(c.Refusal):
                        c.checked_plan(
                            argparse.Namespace(plan=str(self.plan_path)), approved=False
                        )

    def test_moving_target_fails_before_copy_or_activation(self):
        args = argparse.Namespace(
            action="deploy", plan=str(self.plan_path), approve=c.approval(self.plan)
        )
        with (
            patch.object(c, "verify_system"),
            patch.object(
                c,
                "remote_state",
                return_value={
                    "profile": self.plan["system"],
                    "running": self.plan["system"],
                },
            ),
            patch.object(
                c, "copy_closure", side_effect=AssertionError("copy after stale plan")
            ),
        ):
            with self.assertRaisesRegex(c.Refusal, "changed"):
                c.deployment_action(args)

    def test_unpinned_revision_fails_without_git_nix_or_ssh(self):
        for revision in ("HEAD", "main", "a" * 7, "A" * 40, "a" * 39):
            with (
                self.subTest(revision=revision),
                patch.object(
                    c, "run", side_effect=AssertionError("unpinned execution")
                ),
            ):
                with self.assertRaisesRegex(c.Refusal, "full"):
                    c.repository(self.base, revision, "test-host")

    def test_real_dirty_git_worktree_is_refused(self):
        repo = self.base / "repo"
        repo.mkdir()
        c.run(["git", "init", "--quiet", repo])
        c.run(
            [
                "git",
                "-C",
                repo,
                "-c",
                "user.name=Disposable Test",
                "-c",
                "user.email=test@example.invalid",
                "-c",
                "commit.gpgsign=false",
                "commit",
                "--quiet",
                "--allow-empty",
                "-m",
                "test fixture",
            ]
        )
        revision = c.run(["git", "-C", repo, "rev-parse", "HEAD"]).decode().strip()
        self.assertEqual(c.repository(repo, revision, "test-host"), repo)
        (repo / "untracked").write_text("dirty fixture")
        with self.assertRaisesRegex(c.Refusal, "dirty"):
            c.repository(repo, revision, "test-host")

    def test_restore_requires_explicit_matching_backup_before_ssh(self):
        args = argparse.Namespace(
            program="forgejo-admin",
            action="restore",
            target="operator@test-host",
            backup="/var/backups/forgejo/backup.age",
            approve="/root/approval.json",
            approve_backup="/var/backups/forgejo/other.age",
        )
        with patch.object(
            c, "ssh", side_effect=AssertionError("unapproved destructive restore")
        ):
            with self.assertRaisesRegex(c.Refusal, "exactly matching"):
                c.maintenance(args)


class RevocationSafety(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.key = ec.generate_private_key(ec.SECP256R1())
        self.leaf = self.issue(self.key)
        self.url = c.ACME_ORIGIN + "/acme/acme/revoke-cert"
        self.nonce = "disposable-test-fresh-nonce"

    def issue(self, key, ca=False):
        subject = x509.Name(
            [x509.NameAttribute(NameOID.COMMON_NAME, "Disposable revocation test")]
        )
        now = dt.datetime.now(dt.timezone.utc)
        return (
            x509.CertificateBuilder()
            .subject_name(subject)
            .issuer_name(subject)
            .public_key(key.public_key())
            .serial_number(x509.random_serial_number())
            .not_valid_before(now - dt.timedelta(minutes=1))
            .not_valid_after(now + dt.timedelta(hours=1))
            .add_extension(
                x509.BasicConstraints(ca=ca, path_length=None), critical=True
            )
            .sign(key, hashes.SHA256())
        )

    def decode(self, value):
        return base64.urlsafe_b64decode(value + "=" * (-len(value) % 4))

    def verify(self, document):
        protected = json.loads(self.decode(document["protected"]))
        jwk = protected["jwk"]
        signing_input = (document["protected"] + "." + document["payload"]).encode(
            "ascii"
        )
        signature = self.decode(document["signature"])

        def integer(name):
            return int.from_bytes(self.decode(jwk[name]), "big")

        if jwk["kty"] == "RSA":
            public_key = rsa.RSAPublicNumbers(integer("e"), integer("n")).public_key()
            public_key.verify(
                signature, signing_input, padding.PKCS1v15(), hashes.SHA256()
            )
        else:
            curves = {
                "P-256": (ec.SECP256R1, hashes.SHA256, 32),
                "P-384": (ec.SECP384R1, hashes.SHA384, 48),
                "P-521": (ec.SECP521R1, hashes.SHA512, 66),
            }
            curve, digest, width = curves[jwk["crv"]]
            self.assertEqual(len(signature), width * 2)
            public_key = ec.EllipticCurvePublicNumbers(
                integer("x"), integer("y"), curve()
            ).public_key()
            der = utils.encode_dss_signature(
                int.from_bytes(signature[:width], "big"),
                int.from_bytes(signature[width:], "big"),
            )
            public_key.verify(der, signing_input, ec.ECDSA(digest()))

    def test_real_rsa_and_all_supported_ec_jws_authorizations(self):
        keys = [
            rsa.generate_private_key(public_exponent=65537, key_size=2048),
            ec.generate_private_key(ec.SECP256R1()),
            ec.generate_private_key(ec.SECP384R1()),
            ec.generate_private_key(ec.SECP521R1()),
        ]
        for key in keys:
            with self.subTest(key=type(key).__name__, size=key.key_size):
                cert = self.issue(key)
                signed = c.acme_jws(key, cert, self.url, self.nonce, 0)
                self.verify(signed)
                protected = json.loads(self.decode(signed["protected"]))
                self.assertEqual(set(protected), {"alg", "jwk", "nonce", "url"})
                self.assertNotIn("kid", protected)
                self.assertNotIn("d", protected["jwk"])
                self.assertEqual(protected["nonce"], self.nonce)
                self.assertEqual(protected["url"], self.url)
                payload = json.loads(self.decode(signed["payload"]))
                self.assertEqual(
                    self.decode(payload["certificate"]),
                    cert.public_bytes(serialization.Encoding.DER),
                )
                self.assertEqual(payload["reason"], 0)
                # A real signature verifier rejects a changed certificate/reason.
                tampered = {
                    **signed,
                    "payload": c.base64url(c.canonical({**payload, "reason": 1})),
                }
                with self.assertRaises(InvalidSignature):
                    self.verify(tampered)
                changed = {
                    **signed,
                    "protected": c.base64url(
                        c.canonical({**protected, "nonce": "another-fresh-nonce"})
                    ),
                }
                with self.assertRaises(InvalidSignature):
                    self.verify(changed)

    def test_nonmatching_private_key_is_not_authorized(self):
        other = ec.generate_private_key(ec.SECP256R1())
        with self.assertRaisesRegex(c.Refusal, "does not match"):
            c.acme_jws(other, self.leaf, self.url, self.nonce, 0)

    def test_unsupported_or_weak_signing_keys_are_rejected(self):
        for key in (
            ed25519.Ed25519PrivateKey.generate(),
            rsa.generate_private_key(public_exponent=65537, key_size=1024),
        ):
            with self.subTest(key=type(key).__name__), self.assertRaises(c.Refusal):
                c.acme_algorithm(key)

    def test_cross_origin_or_malformed_authorization_inputs_cannot_be_signed(self):
        for url in (
            "http://localhost:9700/acme/acme/revoke-cert",
            "https://evil.example/acme/acme/revoke-cert",
            "https://localhost:443/acme/acme/revoke-cert",
            "https://user@localhost:9700/acme/acme/revoke-cert",
            self.url + "?redirect=evil",
            self.url + "#fragment",
            c.ACME_ORIGIN + "/acme/acme/../revoke-cert",
            c.ACME_ORIGIN + "/acme/acme/%2e%2e/revoke-cert",
        ):
            with self.subTest(url=url), self.assertRaises(c.Refusal):
                c.acme_jws(self.key, self.leaf, url, self.nonce, 0)
        for nonce in (None, "", "padded=", "nonce\ninjection", " "):
            with self.subTest(nonce=nonce), self.assertRaises(c.Refusal):
                c.acme_jws(self.key, self.leaf, self.url, nonce, 0)

    def test_ca_revocation_and_mismatched_material_fail_before_network(self):
        leaf_path = self.base / "leaf.crt"
        key_path = self.base / "leaf.key"
        root_path = self.base / "root.crt"
        root_key = ec.generate_private_key(ec.SECP384R1())
        root = self.issue(root_key, ca=True)
        root_path.write_bytes(root.public_bytes(serialization.Encoding.PEM))
        leaf_path.write_bytes(root.public_bytes(serialization.Encoding.PEM))
        key_path.write_bytes(
            self.key.private_bytes(
                serialization.Encoding.PEM,
                serialization.PrivateFormat.PKCS8,
                serialization.NoEncryption(),
            )
        )
        args = argparse.Namespace(
            target="operator@test-host",
            certificate=str(leaf_path),
            private_key=str(key_path),
            root=str(root_path),
            key_password_file=None,
            reason=0,
        )
        with patch.object(
            c,
            "acme_request",
            side_effect=AssertionError("unauthorized network request"),
        ):
            with self.assertRaisesRegex(c.Refusal, "leaf certificates"):
                c.revoke(args)
            leaf_path.write_bytes(
                self.issue(root_key).public_bytes(serialization.Encoding.PEM)
            )
            with self.assertRaisesRegex(c.Refusal, "does not match"):
                c.revoke(args)

    def test_encrypted_leaf_key_uses_private_password_file(self):
        leaf_path, key_path = self.base / "leaf.crt", self.base / "leaf.key"
        root_path, password_path = self.base / "root.crt", self.base / "password"
        leaf_path.write_bytes(self.leaf.public_bytes(serialization.Encoding.PEM))
        root_path.write_bytes(
            self.issue(ec.generate_private_key(ec.SECP384R1()), ca=True).public_bytes(
                serialization.Encoding.PEM
            )
        )
        password = b"disposable-test-password-only"
        password_path.write_bytes(password + b"\n")
        key_path.write_bytes(
            self.key.private_bytes(
                serialization.Encoding.PEM,
                serialization.PrivateFormat.PKCS8,
                serialization.BestAvailableEncryption(password),
            )
        )
        args = argparse.Namespace(
            certificate=str(leaf_path),
            private_key=str(key_path),
            root=str(root_path),
            key_password_file=str(password_path),
        )
        cert, key = c.revocation_material(args)
        self.assertEqual(
            c.public_bytes(cert.public_key()), c.public_bytes(key.public_key())
        )
        password_path.chmod(0o644)
        with self.assertRaisesRegex(c.Refusal, "mode 0600"):
            c.revocation_material(args)


if __name__ == "__main__":
    os.umask(0o077)
    unittest.main(verbosity=2)
