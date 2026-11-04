"""Consumer-facing regressions; run with Python including cryptography, without production material."""

import datetime
import importlib.util
import io
from pathlib import Path
import tarfile
import tempfile
import unittest

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.x509.oid import NameOID


def load(name, filename):
    spec = importlib.util.spec_from_file_location(
        name, Path(__file__).with_name(filename)
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


materials = load("materials", "validate-materials.py")
maintenance = load("maintenance", "maintenance.py")


def certificate(subject, issuer, key, signing_key, path_length, expires, serial):
    now = datetime.datetime.now(datetime.timezone.utc)
    return (
        x509.CertificateBuilder()
        .subject_name(subject)
        .issuer_name(issuer)
        .public_key(key.public_key())
        .serial_number(serial)
        .not_valid_before(now - datetime.timedelta(days=1))
        .not_valid_after(expires)
        .add_extension(
            x509.BasicConstraints(ca=True, path_length=path_length), critical=True
        )
        .add_extension(
            x509.KeyUsage(False, False, False, False, False, True, True, False, False),
            critical=True,
        )
        .sign(signing_key, hashes.SHA256())
    )


class MaterialTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary.name)
        self.root_key = ec.generate_private_key(ec.SECP256R1())
        self.key = ec.generate_private_key(ec.SECP256R1())
        self.root_name = x509.Name(
            [x509.NameAttribute(NameOID.COMMON_NAME, "test-only root")]
        )
        self.issuer_name = x509.Name(
            [x509.NameAttribute(NameOID.COMMON_NAME, "test-only issuer")]
        )
        now = datetime.datetime.now(datetime.timezone.utc)
        self.root = certificate(
            self.root_name,
            self.root_name,
            self.root_key,
            self.root_key,
            1,
            now + datetime.timedelta(days=10),
            1,
        )
        self.issuer = certificate(
            self.issuer_name,
            self.root_name,
            self.key,
            self.root_key,
            0,
            now + datetime.timedelta(days=2),
            2,
        )
        for name, value in (("root", self.root), ("certificate", self.issuer)):
            (self.directory / name).write_bytes(
                value.public_bytes(serialization.Encoding.PEM)
            )
        (self.directory / "key").write_bytes(
            self.key.private_bytes(
                serialization.Encoding.PEM,
                serialization.PrivateFormat.PKCS8,
                serialization.BestAvailableEncryption(b"test-only-password"),
            )
        )
        (self.directory / "password").write_bytes(b"test-only-password\n")

    def tearDown(self):
        self.temporary.cleanup()

    def validate(self, **kwargs):
        return materials.validate(
            *(
                self.directory / name
                for name in ("root", "certificate", "key", "password")
            ),
            **kwargs,
        )

    def test_valid_chain_and_encrypted_key(self):
        result = self.validate(fingerprint=self.root.fingerprint(hashes.SHA256()).hex())
        self.assertEqual(
            result["intermediate_sha256"],
            self.issuer.fingerprint(hashes.SHA256()).hex(),
        )

    def test_fingerprint_mismatch_fails_closed(self):
        with self.assertRaises(ValueError):
            self.validate(fingerprint="00" * 32)

    def test_wrong_password_fails_closed(self):
        (self.directory / "password").write_bytes(b"incorrect-test-password")
        with self.assertRaises(ValueError):
            self.validate()

    def test_mismatched_private_key_fails_closed(self):
        other_key = ec.generate_private_key(ec.SECP256R1())
        (self.directory / "key").write_bytes(
            other_key.private_bytes(
                serialization.Encoding.PEM,
                serialization.PrivateFormat.PKCS8,
                serialization.BestAvailableEncryption(b"test-only-password"),
            )
        )
        with self.assertRaises(ValueError):
            self.validate()

    def test_unconstrained_intermediate_fails_closed(self):
        issuer = certificate(
            self.issuer_name,
            self.root_name,
            self.key,
            self.root_key,
            None,
            datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=2),
            3,
        )
        (self.directory / "certificate").write_bytes(
            issuer.public_bytes(serialization.Encoding.PEM)
        )
        with self.assertRaises(ValueError):
            self.validate()

    def test_root_crl_revoked_intermediate_fails_closed(self):
        now = datetime.datetime.now(datetime.timezone.utc)
        revoked = (
            x509.RevokedCertificateBuilder()
            .serial_number(2)
            .revocation_date(now)
            .build()
        )
        crl = (
            x509.CertificateRevocationListBuilder()
            .issuer_name(self.root_name)
            .last_update(now - datetime.timedelta(minutes=1))
            .next_update(now + datetime.timedelta(days=1))
            .add_revoked_certificate(revoked)
            .sign(self.root_key, hashes.SHA256())
        )
        path = self.directory / "root.crl"
        path.write_bytes(crl.public_bytes(serialization.Encoding.PEM))
        with self.assertRaises(ValueError):
            self.validate(crl_path=path)


class ArchiveTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary.name)
        self.executor = maintenance.Executor({"tools": {}})

    def tearDown(self):
        self.temporary.cleanup()

    def unpack(self, members):
        archive = self.directory / "backup.tar"
        with tarfile.open(archive, "w") as output:
            for name, kind, value in members:
                info = tarfile.TarInfo(name)
                if kind == "symlink":
                    info.type = tarfile.SYMTYPE
                    info.linkname = value
                    output.addfile(info)
                elif kind == "directory":
                    info.type = tarfile.DIRTYPE
                    info.mode = 0o700
                    output.addfile(info)
                else:
                    data = value.encode()
                    info.size = len(data)
                    output.addfile(info, io.BytesIO(data))
        extracted = self.directory / "extracted"
        extracted.mkdir()
        return self.executor.unpack(archive, extracted)

    def test_traversal_rejected(self):
        with self.assertRaises(maintenance.MaintenanceError):
            self.unpack([("../escape", "file", "not extracted")])

    def test_symlink_parent_rejected(self):
        with self.assertRaises(maintenance.MaintenanceError):
            self.unpack(
                [
                    ("state", "directory", ""),
                    ("state/link", "symlink", "/etc"),
                    ("state/link/passwd", "file", "not extracted"),
                ]
            )

    def test_noncanonical_symlink_cannot_escape_staging(self):
        outside = self.directory / "outside"
        outside.mkdir()
        with self.assertRaises(maintenance.MaintenanceError):
            self.unpack(
                [
                    ("state", "directory", ""),
                    ("state/./link", "symlink", str(outside)),
                    ("state/link/probe", "file", "not extracted"),
                ]
            )
        self.assertFalse((outside / "probe").exists())

    def test_duplicate_rejected(self):
        with self.assertRaises(maintenance.MaintenanceError):
            self.unpack(
                [("manifest.json", "file", "{}"), ("manifest.json", "file", "{}")]
            )

    def test_native_forgejo_store_symlink_preserved(self):
        self.assertEqual(
            self.unpack(
                [
                    ("manifest.json", "file", "{}"),
                    ("state", "directory", ""),
                    ("state/locale", "symlink", "/nix/store/test-only-locale"),
                ]
            ),
            {},
        )
        self.assertTrue((self.directory / "extracted/state/locale").is_symlink())


if __name__ == "__main__":
    unittest.main()
