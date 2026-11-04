"""Validate supplied issuer material without generating or modifying CA state."""

import argparse
import datetime
import json
import os
from pathlib import Path
import sys

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization


def validate(
    root_path,
    certificate_path,
    key_path,
    password_path,
    fingerprint=None,
    crl_path=None,
):
    certificate_bytes = [
        Path(path).read_bytes().strip() for path in (root_path, certificate_path)
    ]
    for data in certificate_bytes:
        if (
            data.count(b"-----BEGIN CERTIFICATE-----") != 1
            or not data.startswith(b"-----BEGIN CERTIFICATE-----")
            or not data.endswith(b"-----END CERTIFICATE-----")
            or b"PRIVATE KEY" in data
        ):
            raise ValueError(
                "Each public CA certificate file must contain exactly one certificate and no private key"
            )
    root, issuer = (x509.load_pem_x509_certificate(data) for data in certificate_bytes)
    now = datetime.datetime.now(datetime.timezone.utc)
    for certificate in (root, issuer):
        if (
            not certificate.not_valid_before_utc
            <= now
            < certificate.not_valid_after_utc
        ):
            raise ValueError("CA certificate is not currently valid")
        constraints = certificate.extensions.get_extension_for_class(
            x509.BasicConstraints
        )
        usage = certificate.extensions.get_extension_for_class(x509.KeyUsage)
        if not constraints.critical or not constraints.value.ca:
            raise ValueError("CA must have critical CA basic constraints")
        if (
            not usage.critical
            or not usage.value.key_cert_sign
            or not usage.value.crl_sign
        ):
            raise ValueError("CA must have critical certificate/CRL signing key usage")
    root_constraints = root.extensions.get_extension_for_class(
        x509.BasicConstraints
    ).value
    if root_constraints.path_length is not None and root_constraints.path_length < 1:
        raise ValueError("Root path length does not permit an intermediate")
    if (
        issuer.extensions.get_extension_for_class(
            x509.BasicConstraints
        ).value.path_length
        != 0
    ):
        raise ValueError("Intermediate must have pathlen:0")
    root.verify_directly_issued_by(root)
    issuer.verify_directly_issued_by(root)
    if issuer.not_valid_after_utc > root.not_valid_after_utc:
        raise ValueError("Intermediate outlives root")
    actual_fingerprint = root.fingerprint(hashes.SHA256()).hex()
    if fingerprint and actual_fingerprint != fingerprint.lower().replace(":", ""):
        raise ValueError("Root fingerprint mismatch")
    password = Path(password_path).read_bytes().rstrip(b"\r\n")
    if not password:
        raise ValueError("Intermediate password must not be empty")
    key_bytes = Path(key_path).read_bytes()
    if b"ENCRYPTED" not in key_bytes:
        raise ValueError("Intermediate private key must be encrypted PEM")
    key = serialization.load_pem_private_key(key_bytes, password=password)
    public_format = (
        serialization.Encoding.DER,
        serialization.PublicFormat.SubjectPublicKeyInfo,
    )
    if key.public_key().public_bytes(
        *public_format
    ) != issuer.public_key().public_bytes(*public_format):
        raise ValueError("Intermediate key does not match certificate")
    if crl_path:
        crl = x509.load_pem_x509_crl(Path(crl_path).read_bytes())
        if crl.issuer != root.subject or not crl.is_signature_valid(root.public_key()):
            raise ValueError("Root CRL signature mismatch")
        if (
            crl.next_update_utc is None
            or not crl.last_update_utc <= now < crl.next_update_utc
        ):
            raise ValueError("Root CRL is not current")
        if crl.get_revoked_certificate_by_serial_number(issuer.serial_number):
            raise ValueError("Intermediate is revoked by supplied root CRL")
    return {
        "root_sha256": actual_fingerprint,
        "intermediate_sha256": issuer.fingerprint(hashes.SHA256()).hex(),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", required=True)
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--credentials", action="store_true")
    source.add_argument("--material-directory")
    args = parser.parse_args()
    cfg = json.loads(Path(args.config).read_text())
    paths = cfg["materials"].copy()
    if args.credentials or args.material_directory:
        directory = Path(
            os.environ["CREDENTIALS_DIRECTORY"]
            if args.credentials
            else args.material_directory
        )
        paths = {name: str(directory / name) for name in paths}
    result = validate(
        paths["root"],
        paths["certificate"],
        paths["key"],
        paths["password"],
        cfg["fingerprint"],
        paths.get("crl"),
    )
    print(json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print(
            "PKI material validation failed; check chain, CA attributes, validity, fingerprint, encrypted key/password and CRL",
            file=sys.stderr,
        )
        sys.exit(1)
