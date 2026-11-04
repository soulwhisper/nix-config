#!/usr/bin/env python3
"""Controller-only PKI preparation and explicitly approved NixOS deployment.

Secrets are passed over pipes, never argv. The only plaintext private material on
persistent storage is a password-encrypted PKCS#8 key; its password is age encrypted.
"""

import argparse
import base64
import datetime as dt
import fcntl
import hashlib
import http.client
import json
import os
from pathlib import Path
import platform
import re
import secrets
import shlex
import socket
import ssl
import stat
import subprocess
import sys
import tempfile
import urllib.parse

import yaml
from cryptography import x509
from cryptography.exceptions import InvalidSignature, UnsupportedAlgorithm
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, padding, rsa, utils
from cryptography.x509.oid import NameOID


class Refusal(Exception):
    pass


def require(condition, message):
    if not condition:
        raise Refusal(message)


def run(argv, *, data=None, sensitive=False, env=None, cwd=None):
    # Never include argv or subprocess output in an exception: either may name a
    # secret input or (for sops/age) include private diagnostic material.
    result = subprocess.run(
        [str(a) for a in argv],
        input=data,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE if sensitive else None,
        env=env,
        cwd=cwd,
        check=False,
    )
    require(
        result.returncode == 0,
        f"{Path(str(argv[0])).name} failed (exit {result.returncode})",
    )
    return result.stdout


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":")).encode()


def emit(value):
    print(json.dumps(value, indent=2, sort_keys=True))


def private_file(path):
    path = Path(path)
    info = path.lstat()
    require(
        stat.S_ISREG(info.st_mode)
        and info.st_uid == os.getuid()
        and not info.st_mode & 0o077,
        "private input must be an owned regular file with mode 0600 or stricter",
    )
    return path


def private_directory(path):
    path = Path(path).absolute()
    info = path.lstat()
    require(
        stat.S_ISDIR(info.st_mode)
        and info.st_uid == os.getuid()
        and not info.st_mode & 0o077,
        "controller directory must be owned, non-symlink, and mode 0700",
    )
    return path


def exclusive_write(path, data, mode=0o600):
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, mode)
    with os.fdopen(fd, "wb") as stream:
        stream.write(data)
        stream.flush()
        os.fsync(stream.fileno())


def recipients(values):
    require(
        values and len(values) == len(set(values)),
        "explicit, unique age recipients are required",
    )
    for value in values:
        require(
            re.fullmatch(r"age1[0-9a-z]{58}", value),
            "only native age public recipients are supported",
        )
    return values


def generate(args):
    recipient_list = recipients(args.recipient)
    directory = Path(args.directory).absolute()
    require(not directory.exists(), "generation requires a NEW controller directory")
    require(
        args.common_name and not any(ord(c) < 32 for c in args.common_name),
        "invalid common name",
    )
    # Refuse obvious store/runtime target locations; generation is deliberately a
    # controller operation and has no SSH or target-host mode.
    require(
        not str(directory).startswith(("/nix/store/", "/run/", "/var/lib/step-ca/")),
        "key generation is only allowed in an explicit controller workspace",
    )
    key = ec.generate_private_key(ec.SECP384R1())
    password = base64.urlsafe_b64encode(secrets.token_bytes(48))
    encrypted_key = key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.BestAvailableEncryption(password),
    )
    csr = (
        x509.CertificateSigningRequestBuilder()
        .subject_name(
            x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, args.common_name)])
        )
        .sign(key, hashes.SHA384())
    )
    command = ["age", "--encrypt"]
    for recipient in recipient_list:
        command += ["--recipient", recipient]
    encrypted_password = run(command, data=password + b"\n", sensitive=True)
    directory.mkdir(mode=0o700)
    # No plaintext key or password is ever written, including on failure.
    exclusive_write(directory / "intermediate.key", encrypted_key)
    exclusive_write(directory / "intermediate-password.age", encrypted_password)
    exclusive_write(
        directory / "intermediate.csr", csr.public_bytes(serialization.Encoding.PEM)
    )
    emit(
        {
            "directory": str(directory),
            "csr": str(directory / "intermediate.csr"),
            "csr_sha256": hashlib.sha256(
                csr.public_bytes(serialization.Encoding.DER)
            ).hexdigest(),
        }
    )


def fingerprint(value):
    value = value.lower().replace(":", "")
    require(
        re.fullmatch(r"[0-9a-f]{64}", value),
        "root fingerprint must be a full SHA-256 hexadecimal fingerprint",
    )
    return value


def certificate(path):
    data = Path(path).read_bytes()
    require(
        data.count(b"-----BEGIN CERTIFICATE-----") == 1
        and data.count(b"-----END CERTIFICATE-----") == 1,
        "each certificate file must contain exactly one PEM certificate",
    )
    cert = x509.load_pem_x509_certificate(data)
    require(
        data.strip() == cert.public_bytes(serialization.Encoding.PEM).strip(),
        "certificate file must contain only its PEM certificate",
    )
    return cert


def public_bytes(key):
    return key.public_bytes(
        serialization.Encoding.DER, serialization.PublicFormat.SubjectPublicKeyInfo
    )


def validate_material(args):
    directory = private_directory(args.directory)
    encrypted_key = private_file(directory / "intermediate.key").read_bytes()
    password_path = private_file(directory / "intermediate-password.age")
    command = ["age", "--decrypt"]
    require(args.identity, "at least one age identity file is required")
    for identity in args.identity:
        command += ["--identity", str(private_file(identity))]
    command += [str(password_path)]
    password = run(command, sensitive=True).rstrip(b"\n")
    require(
        password and b"\n" not in password and b"\r" not in password,
        "invalid intermediate password",
    )
    require(
        b"-----BEGIN ENCRYPTED PRIVATE KEY-----" in encrypted_key,
        "intermediate key must be password-encrypted PKCS#8",
    )
    key = serialization.load_pem_private_key(encrypted_key, password=password)
    require(
        isinstance(key, ec.EllipticCurvePrivateKey) and key.curve.key_size >= 256,
        "controller intermediate key must be an EC key of at least 256 bits",
    )
    csr = x509.load_pem_x509_csr((directory / "intermediate.csr").read_bytes())
    require(csr.is_signature_valid, "CSR signature is invalid")
    root = certificate(args.root)
    intermediate = certificate(args.certificate)
    require(
        root.fingerprint(hashes.SHA256()).hex() == fingerprint(args.root_fingerprint),
        "root fingerprint does not match the out-of-band approved fingerprint",
    )
    now = dt.datetime.now(dt.timezone.utc)
    for cert, label in [(root, "root"), (intermediate, "intermediate")]:
        require(
            cert.not_valid_before_utc <= now < cert.not_valid_after_utc,
            f"{label} certificate is not currently valid",
        )
        constraints = cert.extensions.get_extension_for_class(x509.BasicConstraints)
        usage = cert.extensions.get_extension_for_class(x509.KeyUsage)
        require(
            constraints.critical and constraints.value.ca,
            f"{label} must have critical CA basic constraints",
        )
        require(
            usage.critical and usage.value.key_cert_sign and usage.value.crl_sign,
            f"{label} must have critical certificate/CRL signing key usage",
        )
        for extension in cert.extensions:
            require(
                not (
                    extension.critical
                    and isinstance(extension.value, x509.UnrecognizedExtension)
                ),
                f"{label} has an unsupported critical extension",
            )
    require(root.subject == root.issuer, "root must be self-issued")
    root.verify_directly_issued_by(root)
    intermediate.verify_directly_issued_by(root)
    run(
        [
            "openssl",
            "verify",
            "-x509_strict",
            "-auth_level",
            "2",
            "-CAfile",
            str(Path(args.root).absolute()),
            str(Path(args.certificate).absolute()),
        ],
        sensitive=True,
    )
    require(
        public_bytes(root.public_key()) != public_bytes(intermediate.public_key()),
        "root and intermediate must not reuse a private key",
    )
    root_constraints = root.extensions.get_extension_for_class(
        x509.BasicConstraints
    ).value
    require(
        root_constraints.path_length is None or root_constraints.path_length >= 1,
        "root path length does not permit an intermediate",
    )
    require(
        intermediate.extensions.get_extension_for_class(
            x509.BasicConstraints
        ).value.path_length
        == 0,
        "intermediate must have pathlen:0",
    )
    require(
        intermediate.not_valid_after_utc <= root.not_valid_after_utc
        and intermediate.not_valid_before_utc >= root.not_valid_before_utc,
        "intermediate lifetime must fit inside the root lifetime",
    )
    require(
        intermediate.subject == csr.subject,
        "signed intermediate subject differs from the CSR",
    )
    require(
        public_bytes(key.public_key())
        == public_bytes(csr.public_key())
        == public_bytes(intermediate.public_key()),
        "key, CSR and certificate do not match",
    )
    return (
        {
            "root-ca-crt": root.public_bytes(serialization.Encoding.PEM).decode(),
            "intermediate-crt": intermediate.public_bytes(
                serialization.Encoding.PEM
            ).decode(),
            "intermediate-key": encrypted_key.decode(),
            "intermediate-password": password.decode("ascii"),
        },
        root,
        intermediate,
    )


def validate(args):
    _, root, intermediate = validate_material(args)
    emit(
        {
            "valid": True,
            "root_sha256": root.fingerprint(hashes.SHA256()).hex(),
            "intermediate_sha256": intermediate.fingerprint(hashes.SHA256()).hex(),
            "intermediate_expires": intermediate.not_valid_after_utc.isoformat(),
        }
    )


def sops_metadata(document):
    require(
        isinstance(document, dict) and isinstance(document.get("sops"), dict),
        "missing SOPS metadata",
    )
    metadata = document["sops"]
    allowed = {
        "kms",
        "gcp_kms",
        "azure_kv",
        "hc_vault",
        "age",
        "lastmodified",
        "mac",
        "version",
        "unencrypted_suffix",
    }
    require(
        not set(metadata) - allowed,
        "unsupported SOPS protection metadata; refusing to rekey",
    )
    for name in ("kms", "gcp_kms", "azure_kv", "hc_vault"):
        require(not metadata.get(name), "only simple age-only SOPS files are supported")
    entries = metadata.get("age")
    require(
        isinstance(entries, list) and entries,
        "existing SOPS file has no age recipients",
    )
    values = []
    for entry in entries:
        require(
            isinstance(entry, dict)
            and set(entry) == {"recipient", "enc"}
            and isinstance(entry["enc"], str),
            "unsupported SOPS age stanza",
        )
        values.append(entry["recipient"])
    recipients(values)
    suffix = metadata.get("unencrypted_suffix", "_unencrypted")
    require(
        isinstance(suffix, str)
        and suffix
        and not any(
            key.endswith(suffix)
            for key in (
                "pki",
                "root-ca-crt",
                "intermediate-crt",
                "intermediate-key",
                "intermediate-password",
            )
        ),
        "SOPS unencrypted suffix would expose PKI material",
    )
    return values, suffix


def sops_decrypt(data):
    return json.loads(
        run(
            [
                "sops",
                "--decrypt",
                "--input-type",
                "yaml",
                "--output-type",
                "json",
                "/dev/stdin",
            ],
            data=data,
            sensitive=True,
        )
    )


def stage(args):
    material, _, _ = validate_material(args)
    path = Path(args.sops_file).absolute()
    require(
        path.parent.is_dir() and not path.is_symlink(),
        "SOPS destination must have a real parent and not be a symlink",
    )
    # A stable lock outside the repository survives atomic rename without leaving
    # an untracked sidecar in the controller's clean deployment checkout.
    lock_directory = Path(tempfile.gettempdir()) / (
        "deployment-tools-" + str(os.getuid())
    )
    lock_directory.mkdir(mode=0o700, exist_ok=True)
    private_directory(lock_directory)
    lock_path = lock_directory / (
        hashlib.sha256(os.fsencode(path.resolve())).hexdigest() + ".lock"
    )
    lock_fd = os.open(lock_path, os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW, 0o600)
    # Keep the lock inode after closing it; unlinking would allow split locks.
    with os.fdopen(lock_fd, "a+b") as lock:
        require(
            stat.S_ISREG(os.fstat(lock.fileno()).st_mode)
            and os.fstat(lock.fileno()).st_uid == os.getuid(),
            "unsafe SOPS lock file",
        )
        fcntl.flock(lock, fcntl.LOCK_EX)
        exists = path.exists()
        original = None
        original_stat = None
        if exists:
            require(
                not args.recipient, "--recipient is permitted only for a NEW SOPS file"
            )
            with os.fdopen(os.open(path, os.O_RDONLY | os.O_NOFOLLOW), "rb") as stream:
                original_stat = os.fstat(stream.fileno())
                require(
                    stat.S_ISREG(original_stat.st_mode)
                    and original_stat.st_nlink == 1
                    and original_stat.st_uid == os.getuid(),
                    "SOPS input must be an owned regular file without hard links",
                )
                original = stream.read()
            ciphertext = yaml.safe_load(original)
            recipient_list, suffix = sops_metadata(ciphertext)
            document = sops_decrypt(original)
            require(
                isinstance(document, dict) and "sops" not in document,
                "unsupported decrypted SOPS structure",
            )
        else:
            recipient_list, suffix = recipients(args.recipient), "_unencrypted"
            document = {}
        require(
            "pki" not in document or isinstance(document["pki"], dict),
            "existing pki field is not an object",
        )
        document.setdefault("pki", {}).update(material)
        # Plaintext travels only through anonymous pipes and process memory.
        # Explicit recipients and suffix preserve the supported protection policy.
        encrypted = run(
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
                ",".join(recipient_list),
                "--unencrypted-suffix",
                suffix,
                "/dev/stdin",
            ],
            data=canonical(document),
            sensitive=True,
        )
        new_recipients, new_suffix = sops_metadata(yaml.safe_load(encrypted))
        require(
            set(new_recipients) == set(recipient_list) and new_suffix == suffix,
            "SOPS recipient/protection policy changed",
        )
        require(
            sops_decrypt(encrypted) == document, "SOPS round-trip changed secret values"
        )
        # Compare before replacing to detect editors which do not honor our lock.
        if exists:
            current = path.lstat()
            require(
                (current.st_dev, current.st_ino, current.st_mtime_ns, current.st_size)
                == (
                    original_stat.st_dev,
                    original_stat.st_ino,
                    original_stat.st_mtime_ns,
                    original_stat.st_size,
                )
                and path.read_bytes() == original,
                "SOPS file changed concurrently; refusing replacement",
            )
        else:
            require(not path.exists(), "SOPS destination appeared concurrently")
        fd, temporary = tempfile.mkstemp(prefix="." + path.name + ".", dir=path.parent)
        try:
            with os.fdopen(fd, "wb") as stream:
                stream.write(encrypted)
                stream.flush()
                os.fsync(stream.fileno())
            os.chmod(
                temporary, stat.S_IMODE(original_stat.st_mode) if exists else 0o600
            )
            if exists:
                os.replace(temporary, path)
            else:
                # Atomic create-without-overwrite, even against a non-cooperating writer.
                os.link(temporary, path)
                os.unlink(temporary)
            directory_fd = os.open(path.parent, os.O_RDONLY)
            try:
                os.fsync(directory_fd)
            finally:
                os.close(directory_fd)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)
    emit(
        {
            "staged": str(path),
            "fields": ["pki/" + key for key in material],
            "recipient_count": len(recipient_list),
        }
    )


TARGET_RE = re.compile(
    r"(?:[a-zA-Z_][a-zA-Z0-9_-]*@)?[a-zA-Z0-9](?:[a-zA-Z0-9.-]*[a-zA-Z0-9])?"
)
STORE_RE = re.compile(
    r"/nix/store/[0123456789abcdfghijklmnpqrsvwxyz]{32}-[a-zA-Z0-9+._?=-]+"
)
SSH_OPTIONS = [
    "-oBatchMode=yes",
    "-oStrictHostKeyChecking=yes",
    "-oClearAllForwardings=yes",
    "-oPermitLocalCommand=no",
    "-oUpdateHostKeys=no",
]


def target(value):
    require(
        isinstance(value, str) and TARGET_RE.fullmatch(value),
        "target must be an explicit [user@]hostname (no flags, ports, whitespace or shell syntax)",
    )
    return value


def store_path(value):
    require(
        isinstance(value, str) and STORE_RE.fullmatch(value),
        "expected an absolute, top-level /nix/store path",
    )
    return value


def ssh(host, argv):
    # OpenSSH sends one remote shell string; quote every argument, never concatenate
    # untrusted values into shell source. Strict options also apply to nix copy.
    return run(
        ["ssh", *SSH_OPTIONS, "--", target(host), shlex.join([str(a) for a in argv])]
    )


def nix_environment():
    environment = dict(os.environ)
    # Do not inherit an environment override capable of disabling host key checks.
    environment["NIX_SSHOPTS"] = " ".join(SSH_OPTIONS)
    return environment


def repository(repo, revision, host):
    require(
        re.fullmatch(r"[0-9a-f]{40}", revision or ""),
        "revision must be a full, lowercase 40-character Git commit",
    )
    require(
        re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9_-]*", host or ""),
        "invalid NixOS configuration name",
    )
    path = Path(repo).resolve(strict=True)
    require(path.is_dir(), "repository must be a directory")
    root = run(["git", "-C", path, "rev-parse", "--show-toplevel"]).decode().strip()
    require(Path(root).resolve() == path, "--repo must name the repository root")
    require(
        not run(
            [
                "git",
                "-C",
                path,
                "status",
                "--porcelain=v1",
                "--untracked-files=all",
                "--ignore-submodules=none",
            ]
        ),
        "repository is dirty, including untracked files or submodule changes",
    )
    current = (
        run(["git", "-C", path, "rev-parse", "--verify", "HEAD^{commit}"])
        .decode()
        .strip()
    )
    require(
        current == revision, "repository HEAD must equal the explicitly pinned revision"
    )
    run(["git", "-C", path, "cat-file", "-e", revision + "^{commit}"])
    return path


def flake_reference(path, revision, host):
    return (
        "git+"
        + path.as_uri()
        + "?rev="
        + revision
        + "#nixosConfigurations."
        + host
        + ".config.system.build.toplevel"
    )


def verify_system(repo, revision, host, system):
    path = repository(repo, revision, host)
    store_path(system)
    expected = (
        run(
            [
                "nix",
                "eval",
                "--raw",
                "--no-write-lock-file",
                flake_reference(path, revision, host) + ".outPath",
            ]
        )
        .decode()
        .strip()
    )
    require(
        system == expected,
        "system path does not match the pinned revision/configuration",
    )
    run(["nix", "path-info", system])
    require(
        (Path(system) / "bin/switch-to-configuration").is_file(),
        "system path is not a NixOS toplevel",
    )
    return path


def build(args):
    path = repository(args.repo, args.revision, args.host)
    command = ["nix", "build", "--no-link", "--print-out-paths", "--no-write-lock-file"]
    if args.builder:
        match = re.fullmatch(r"(ssh(?:-ng)?://)(.+)", args.builder)
        require(
            match,
            "builder must be an explicit ssh://[user@]host or ssh-ng://[user@]host",
        )
        target(match.group(2))
        system_ref = (
            "git+"
            + path.as_uri()
            + "?rev="
            + args.revision
            + "#nixosConfigurations."
            + args.host
            + ".config.nixpkgs.hostPlatform.system"
        )
        build_system = (
            run(["nix", "eval", "--raw", "--no-write-lock-file", system_ref])
            .decode()
            .strip()
        )
        require(
            re.fullmatch(r"[a-z0-9_]+-linux", build_system),
            "builder configuration must target Linux",
        )
        command += [
            "--builders",
            args.builder + " " + build_system + " - 1 1",
            "--max-jobs",
            "0",
        ]
    else:
        require(
            platform.system() == "Linux",
            "Darwin requires an explicit Linux --builder or a CI-prebuilt closure with plan --system",
        )
        # Never pick a target/default remote builder from nix.conf.
        command += ["--builders", ""]
    command += [flake_reference(path, args.revision, args.host)]
    outputs = run(command, env=nix_environment()).decode().splitlines()
    require(len(outputs) == 1, "build must produce exactly one system path")
    store_path(outputs[0])
    print(outputs[0])


def remote_state(host):
    profile = (
        ssh(host, ["readlink", "-e", "/nix/var/nix/profiles/system"]).decode().strip()
    )
    running = ssh(host, ["readlink", "-e", "/run/current-system"]).decode().strip()
    return {"profile": store_path(profile), "running": store_path(running)}


def approval(plan, rollback=False):
    digest = hashlib.sha256(canonical(plan)).hexdigest()
    return ("rollback:" if rollback else "deploy:") + digest


PLAN_FIELDS = {
    "schema",
    "repo",
    "revision",
    "host",
    "target",
    "system",
    "previous_system",
}


def plan(args):
    path = verify_system(args.repo, args.revision, args.host, args.system)
    target(args.target)
    state = remote_state(args.target)
    require(
        state["profile"] == state["running"],
        "target has a pending/inconsistent system profile; reconcile before planning",
    )
    require(args.system != state["profile"], "target is already on this system")
    document = {
        "schema": 1,
        "repo": str(path),
        "revision": args.revision,
        "host": args.host,
        "target": args.target,
        "system": args.system,
        "previous_system": state["profile"],
    }
    exclusive_write(
        args.out, json.dumps(document, indent=2, sort_keys=True).encode() + b"\n"
    )
    emit(
        {
            "plan": str(Path(args.out).absolute()),
            "revision": args.revision,
            "system": args.system,
            "previous_system": state["profile"],
            "approve": approval(document),
            "approve_rollback": approval(document, rollback=True),
        }
    )


def load_plan(path):
    document = json.loads(Path(path).read_bytes())
    require(
        isinstance(document, dict)
        and set(document) == PLAN_FIELDS
        and document["schema"] == 1,
        "invalid deployment plan schema",
    )
    target(document["target"])
    store_path(document["system"])
    store_path(document["previous_system"])
    require(
        document["system"] != document["previous_system"],
        "deployment plan has no change",
    )
    return document


def require_planned_state(document, state, rollback=False):
    if rollback:
        # Failed activation can restore the profile link without restoring runtime
        # state. A separately approved rollback may reconcile either pinned end.
        endpoints = {document["system"], document["previous_system"]}
        valid = state["profile"] in endpoints and state["running"] in endpoints
    else:
        valid = state["profile"] == state["running"] == document["previous_system"]
    require(
        valid,
        "target changed since this plan; create a new plan (or select the matching rollback)",
    )


def checked_plan(args, *, approved=False, rollback=False):
    document = load_plan(args.plan)
    # Approval and local safety checks must precede any remote mutation or Nix work.
    if approved:
        require(
            args.approve == approval(document, rollback=rollback),
            "explicit approval does not match this exact action/revision/system/target plan",
        )
    verify_system(
        document["repo"], document["revision"], document["host"], document["system"]
    )
    state = remote_state(document["target"])
    require_planned_state(document, state, rollback=rollback)
    return document


def copy_closure(document):
    run(
        ["nix", "copy", "--to", "ssh-ng://" + document["target"], document["system"]],
        env=nix_environment(),
    )


def diff_system(document, rollback=False):
    previous = document["system"] if rollback else document["previous_system"]
    following = document["previous_system"] if rollback else document["system"]
    # Fetch the baseline for a real local closure diff, without rebuilding on target.
    run(
        ["nix", "copy", "--from", "ssh-ng://" + document["target"], previous],
        env=nix_environment(),
    )
    if rollback:
        run(
            ["nix", "copy", "--from", "ssh-ng://" + document["target"], following],
            env=nix_environment(),
        )
    result = run(["nvd", "diff", previous, following])
    sys.stdout.buffer.write(result)
    sys.stdout.buffer.flush()


ACTIVATE_SCRIPT = r"""set -euo pipefail
expected_profile=$1
expected_running=$2
next=$3
exec 9>/run/lock/deploymentctl.lock
flock -n 9 || { echo 'another deployment is in progress' >&2; exit 1; }
[ "$(readlink -e /nix/var/nix/profiles/system)" = "$expected_profile" ] || exit 1
[ "$(readlink -e /run/current-system)" = "$expected_running" ] || exit 1
[ -x "$next/bin/switch-to-configuration" ] || exit 1
/run/current-system/sw/bin/nix-env --profile /nix/var/nix/profiles/system --set "$next"
if "$next/bin/switch-to-configuration" switch \
  && [ "$(readlink -e /nix/var/nix/profiles/system)" = "$next" ] \
  && [ "$(readlink -e /run/current-system)" = "$next" ]; then
  exit 0
fi
echo 'activation failed; restoring profile only, NOT activating previous issuer material' >&2
/run/current-system/sw/bin/nix-env --profile /nix/var/nix/profiles/system --set "$expected_profile"
echo 'review target state and use a separately approved deploymentctl rollback if appropriate' >&2
exit 1
"""


def activate_system(document, rollback=False):
    state = remote_state(document["target"])
    require_planned_state(document, state, rollback=rollback)
    previous = state["profile"]
    following = document["previous_system"] if rollback else document["system"]
    ssh(
        document["target"],
        [
            "sudo",
            "-n",
            "--",
            "/bin/sh",
            "-c",
            ACTIVATE_SCRIPT,
            "deploymentctl",
            previous,
            state["running"],
            following,
        ],
    )
    emit(
        {
            "target": document["target"],
            "revision": document["revision"],
            "active_system": following,
            "previous_system": previous,
            "rollback": rollback,
        }
    )


def deployment_action(args):
    rollback = args.action == "rollback"
    mutating = args.action in {"copy", "deploy", "activate", "rollback"}
    document = checked_plan(args, approved=mutating, rollback=rollback)
    if args.action in {"copy", "deploy"}:
        copy_closure(document)
    if args.action in {"diff", "deploy", "activate", "rollback"}:
        diff_system(document, rollback=rollback)
    if args.action in {"deploy", "activate", "rollback"}:
        activate_system(document, rollback=rollback)
    if args.action == "copy":
        emit({"copied": document["system"], "target": document["target"]})


def status(args):
    host = target(args.target)
    state = remote_state(host)
    generations = ssh(
        host,
        ["nix-env", "--profile", "/nix/var/nix/profiles/system", "--list-generations"],
    ).decode()
    emit({"target": host, **state, "generations": generations})


def remote_absolute(value):
    require(
        isinstance(value, str)
        and value.startswith("/")
        and "\x00" not in value
        and not any(part in (".", "..") for part in value.split("/")),
        "maintenance paths must be explicit absolute target paths without dot components",
    )
    return value


def maintenance(args):
    service = "pki" if args.program == "pki-admin" else "forgejo"
    operation = {
        "check": "pki-check",
        "doctor": "forgejo-doctor",
        "backup": service + "-backup",
        "restore": service + "-restore",
    }[args.action]
    command = [
        "sudo",
        "-n",
        "--",
        "/run/current-system/sw/bin/corp-service-maintenance",
        operation,
    ]
    if args.action == "restore":
        remote_absolute(args.backup)
        remote_absolute(args.approve)
        require(
            args.approve_backup == args.backup,
            "restore requires --approve-backup exactly matching the explicit encrypted --backup path",
        )
        command += ["--backup", args.backup, "--approve", args.approve]
    result = ssh(args.target, command)
    sys.stdout.buffer.write(result)
    sys.stdout.buffer.flush()


ACME_ORIGIN = "https://localhost:9700"
ACME_DIRECTORY = ACME_ORIGIN + "/acme/acme/directory"


def base64url(value):
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def acme_endpoint(value):
    require(isinstance(value, str), "ACME endpoint is not a URL")
    parsed = urllib.parse.urlsplit(value)
    require(
        parsed.scheme == "https"
        and parsed.hostname == "localhost"
        and parsed.port == 9700
        and parsed.netloc == "localhost:9700"
        and parsed.path.startswith("/acme/acme/")
        and not parsed.query
        and not parsed.fragment
        and not any(part in (".", "..") for part in parsed.path.split("/"))
        and "%" not in parsed.path
        and not any(ord(char) < 33 for char in value),
        "ACME endpoint must remain on the verified localhost:9700 ACME origin",
    )
    return parsed.path


def acme_nonce(value):
    require(
        isinstance(value, str) and re.fullmatch(r"[A-Za-z0-9_-]{1,1024}", value),
        "ACME response has no valid fresh Replay-Nonce",
    )
    return value


def acme_algorithm(key):
    if isinstance(key, rsa.RSAPrivateKey):
        require(key.key_size >= 2048, "ACME RSA keys must be at least 2048 bits")
        numbers = key.public_key().public_numbers()

        def integer(value):
            return base64url(value.to_bytes((value.bit_length() + 7) // 8, "big"))

        return (
            "RS256",
            {"kty": "RSA", "e": integer(numbers.e), "n": integer(numbers.n)},
            hashes.SHA256(),
            None,
        )
    if isinstance(key, ec.EllipticCurvePrivateKey):
        curves = {
            "secp256r1": ("ES256", "P-256", hashes.SHA256, 32),
            "secp384r1": ("ES384", "P-384", hashes.SHA384, 48),
            "secp521r1": ("ES512", "P-521", hashes.SHA512, 66),
        }
        require(key.curve.name in curves, "ACME EC keys must use P-256, P-384 or P-521")
        algorithm, curve, digest, width = curves[key.curve.name]
        numbers = key.public_key().public_numbers()
        jwk = {
            "kty": "EC",
            "crv": curve,
            "x": base64url(numbers.x.to_bytes(width, "big")),
            "y": base64url(numbers.y.to_bytes(width, "big")),
        }
        return algorithm, jwk, digest(), width
    raise Refusal(
        "unsupported ACME signing key; use RSA >=2048 or EC P-256/P-384/P-521"
    )


def acme_jws(key, cert, url, nonce, reason):
    acme_endpoint(url)
    acme_nonce(nonce)
    require(reason in (0, 1, 3, 4, 5, 9), "unsupported ACME revocation reason")
    require(
        public_bytes(key.public_key()) == public_bytes(cert.public_key()),
        "revocation private key does not match the supplied certificate",
    )
    algorithm, jwk, digest, width = acme_algorithm(key)
    protected = base64url(
        canonical({"alg": algorithm, "jwk": jwk, "nonce": nonce, "url": url})
    )
    payload = base64url(
        canonical(
            {
                "certificate": base64url(cert.public_bytes(serialization.Encoding.DER)),
                "reason": reason,
            }
        )
    )
    signing_input = (protected + "." + payload).encode("ascii")
    if width is None:
        signature = key.sign(signing_input, padding.PKCS1v15(), digest)
    else:
        r, s = utils.decode_dss_signature(key.sign(signing_input, ec.ECDSA(digest)))
        signature = r.to_bytes(width, "big") + s.to_bytes(width, "big")
    return {
        "protected": protected,
        "payload": payload,
        "signature": base64url(signature),
    }


def revocation_material(args):
    leaf = certificate(args.certificate)
    try:
        constraints = leaf.extensions.get_extension_for_class(
            x509.BasicConstraints
        ).value
    except x509.ExtensionNotFound:
        constraints = None
    require(
        constraints is None or not constraints.ca,
        "revoke accepts leaf certificates only, never CA certificates",
    )
    password = None
    if args.key_password_file:
        password = private_file(args.key_password_file).read_bytes().rstrip(b"\r\n")
        require(
            password and b"\n" not in password and b"\r" not in password,
            "key password file must contain one nonempty password",
        )
    key = serialization.load_pem_private_key(
        private_file(args.private_key).read_bytes(), password=password
    )
    require(
        public_bytes(key.public_key()) == public_bytes(leaf.public_key()),
        "revocation private key does not match the supplied certificate",
    )
    acme_algorithm(key)
    root = certificate(args.root)
    require(
        root.extensions.get_extension_for_class(x509.BasicConstraints).value.ca
        and root.subject == root.issuer,
        "TLS trust file must be a public self-issued CA root",
    )
    root.verify_directly_issued_by(root)
    return leaf, key


class TunnelHTTPSConnection(http.client.HTTPSConnection):
    def __init__(self, host, context):
        super().__init__("localhost", 9700, timeout=15, context=context)
        self.target = target(host)
        self.tunnel_process = None

    def connect(self):
        # SSH stdio forwarding over a private socketpair creates no TCP or Unix
        # listener. -W uses only the target's loopback9700, and implies clearing
        # unrelated forwarding settings; preserve strict host-key verification.
        transport, peer = socket.socketpair()
        transport.settimeout(self.timeout)
        try:
            try:
                self.tunnel_process = subprocess.Popen(
                    [
                        "ssh",
                        *SSH_OPTIONS,
                        "-oControlMaster=no",
                        "-oControlPath=none",
                        "-T",
                        "-W",
                        "127.0.0.1:9700",
                        "--",
                        self.target,
                    ],
                    stdin=peer,
                    stdout=peer,
                    stderr=subprocess.DEVNULL,
                )
            finally:
                peer.close()
            self.sock = self._context.wrap_socket(
                transport, server_hostname="localhost"
            )
        except Exception:
            transport.close()
            self.stop_tunnel()
            raise

    def stop_tunnel(self):
        process = self.tunnel_process
        if process is not None:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
            self.tunnel_process = None


def acme_request(host, context, method, url, document=None):
    path = acme_endpoint(url)
    connection = TunnelHTTPSConnection(host, context)
    try:
        body = canonical(document) if document is not None else None
        headers = {"Accept": "application/json", "User-Agent": "pki-admin/1"}
        if body is not None:
            headers["Content-Type"] = "application/jose+json"
        connection.request(method, path, body=body, headers=headers)
        response = connection.getresponse()
        data = response.read(1024 * 1024 + 1)
        require(len(data) <= 1024 * 1024, "ACME response exceeds the allowed size")
        return response.status, response.getheader("Replay-Nonce"), data
    finally:
        connection.close()
        # Do not kill ssh in HTTPConnection.close(): getresponse() may close the
        # connection before the separately owned response body has been read.
        connection.stop_tunnel()


def revoke(args):
    # Validate all local authorization inputs before establishing any connection.
    target(args.target)
    leaf, key = revocation_material(args)
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    context.minimum_version = ssl.TLSVersion.TLSv1_2
    context.load_verify_locations(cafile=str(Path(args.root).absolute()))
    status_code, _, body = acme_request(args.target, context, "GET", ACME_DIRECTORY)
    require(status_code == 200, "ACME directory request failed")
    directory = json.loads(body)
    require(isinstance(directory, dict), "invalid ACME directory response")
    nonce_url = directory.get("newNonce")
    revoke_url = directory.get("revokeCert")
    acme_endpoint(nonce_url)
    acme_endpoint(revoke_url)
    status_code, nonce, _ = acme_request(args.target, context, "HEAD", nonce_url)
    require(status_code in (200, 204), "ACME nonce request failed")
    nonce = acme_nonce(nonce)
    for attempt in range(2):
        signed = acme_jws(key, leaf, revoke_url, nonce, args.reason)
        status_code, next_nonce, body = acme_request(
            args.target, context, "POST", revoke_url, signed
        )
        if status_code == 200:
            break
        # RFC8555 permits a fresh, server-provided nonce retry for badNonce.
        try:
            problem = json.loads(body)
        except (ValueError, UnicodeError):
            problem = {}
        if (
            attempt == 0
            and isinstance(problem, dict)
            and problem.get("type") == "urn:ietf:params:acme:error:badNonce"
        ):
            fresh = acme_nonce(next_nonce)
            require(fresh != nonce, "ACME server repeated a rejected nonce")
            nonce = fresh
            continue
        raise Refusal(
            f"ACME revokeCert failed (HTTP {status_code}); no CA private key was accessed"
        )
    emit(
        {
            "revoked": True,
            "certificate_sha256": leaf.fingerprint(hashes.SHA256()).hex(),
            "target": args.target,
            "reason": args.reason,
        }
    )


def material_arguments(parser):
    parser.add_argument(
        "--directory",
        required=True,
        help="private controller directory produced by generate",
    )
    parser.add_argument(
        "--certificate", required=True, help="root-signed intermediate PEM certificate"
    )
    parser.add_argument(
        "--root", required=True, help="approved public root PEM certificate"
    )
    parser.add_argument(
        "--root-fingerprint",
        required=True,
        help="out-of-band SHA-256 root fingerprint, with optional colons",
    )
    parser.add_argument(
        "--identity",
        action="append",
        required=True,
        help="private age identity file (repeatable)",
    )


def maintenance_parser(sub, name):
    parser = sub.add_parser(
        name,
        help="delegate to the target's root-only corp-service-maintenance executor",
    )
    parser.add_argument(
        "--target",
        required=True,
        help="explicit [user@]hostname; strict SSH host key checking",
    )
    if name == "restore":
        parser.add_argument(
            "--backup", required=True, help="absolute encrypted archive path ON TARGET"
        )
        parser.add_argument(
            "--approve",
            required=True,
            help="absolute root-owned0600 single-use approval JSON ON TARGET: service, sha256, action=restore",
        )
        parser.add_argument(
            "--approve-backup",
            required=True,
            help="repeat --backup exactly to approve destructive restore",
        )
    parser.set_defaults(handler=maintenance)


def parser_for(program):
    parser = argparse.ArgumentParser(prog=program)
    parser.set_defaults(program=program)
    sub = parser.add_subparsers(dest="action", required=True)
    if program == "pki-admin":
        parser.description = "Controller intermediate preparation and atomic age-only SOPS staging; never creates a root or keys on a target."
        generate_parser = sub.add_parser(
            "generate",
            help="create a new P-384 intermediate CSR, encrypted key and age-encrypted password",
        )
        generate_parser.add_argument(
            "--directory", required=True, help="NEW private controller directory"
        )
        generate_parser.add_argument("--common-name", required=True)
        generate_parser.add_argument(
            "--recipient",
            action="append",
            required=True,
            help="native age public recipient (repeatable)",
        )
        generate_parser.set_defaults(handler=generate)
        validate_parser = sub.add_parser(
            "validate",
            help="verify approved root, CA chain/lifetime/pathlen, CSR and encrypted key match",
        )
        material_arguments(validate_parser)
        validate_parser.set_defaults(handler=validate)
        stage_parser = sub.add_parser(
            "stage",
            help="validate then atomically encrypt all four PKI fields, preserving unrelated values and recipients",
        )
        material_arguments(stage_parser)
        stage_parser.add_argument("--sops-file", required=True)
        stage_parser.add_argument(
            "--recipient",
            action="append",
            help="NEW file only; existing recipient sets cannot be replaced",
        )
        stage_parser.set_defaults(handler=stage)
        revoke_parser = sub.add_parser(
            "revoke",
            help="RFC8555 leaf-key revokeCert over a verified, strict-SSH localhost tunnel",
        )
        revoke_parser.add_argument(
            "--target",
            required=True,
            help="explicit [user@]hostname; forwards only target loopback9700",
        )
        revoke_parser.add_argument(
            "--certificate", required=True, help="single leaf PEM certificate to revoke"
        )
        revoke_parser.add_argument(
            "--private-key",
            required=True,
            help="matching owned0600 leaf PEM key; RSA>=2048 or P-256/P-384/P-521",
        )
        revoke_parser.add_argument(
            "--key-password-file",
            help="owned0600 password file for an encrypted leaf key",
        )
        revoke_parser.add_argument(
            "--root",
            required=True,
            help="approved public CA root for TLS verification of localhost",
        )
        revoke_parser.add_argument(
            "--reason",
            type=int,
            choices=[0, 1, 3, 4, 5, 9],
            default=0,
            help="RFC5280 reason (default0 unspecified; 1 key compromise)",
        )
        revoke_parser.set_defaults(handler=revoke)
        for name in ("check", "backup", "restore"):
            maintenance_parser(sub, name)
    elif program == "forgejo-admin":
        parser.description = "Forgejo maintenance through the target's configured encrypted-backup executor and existing sudo authority."
        for name in ("doctor", "backup", "restore"):
            maintenance_parser(sub, name)
    else:
        parser.description = "Build and deploy a clean pinned Git revision; plan binds target, exact NixOS store path and previous profile. No implicit target builder."
        build_parser = sub.add_parser(
            "build",
            help="build locally on Linux, or with an explicit Linux SSH builder; print system path",
        )
        plan_parser = sub.add_parser(
            "plan",
            help="validate CI/local closure against pinned revision and capture target baseline; print approval tokens",
        )
        for child in (build_parser, plan_parser):
            child.add_argument(
                "--repo",
                required=True,
                help="clean Git repository root; HEAD must equal --revision",
            )
            child.add_argument(
                "--revision", required=True, help="full lowercase 40-character commit"
            )
            child.add_argument(
                "--host", required=True, help="nixosConfigurations attribute name"
            )
        build_parser.add_argument(
            "--builder", help="explicit ssh://[user@]Linux-builder (required on Darwin)"
        )
        build_parser.set_defaults(handler=build)
        plan_parser.add_argument(
            "--target", required=True, help="explicit [user@]hostname"
        )
        plan_parser.add_argument(
            "--system",
            required=True,
            help="locally available built/CI-prebuilt NixOS toplevel store path",
        )
        plan_parser.add_argument(
            "--out",
            required=True,
            help="NEW plan JSON path, outside the clean repository",
        )
        plan_parser.set_defaults(handler=plan)
        for name in ("copy", "diff", "deploy", "activate", "rollback"):
            child = sub.add_parser(
                name,
                help={
                    "copy": "copy the approved pinned closure with strict SSH host key verification",
                    "diff": "fetch baseline and show real nvd closure diff, without activation",
                    "deploy": "approved closure copy, diff, then transactional profile switch",
                    "activate": "diff and activate an already-copied closure with explicit approval",
                    "rollback": "diff and restore this plan's exact previous profile; separate rollback approval",
                }[name],
            )
            child.add_argument("--plan", required=True)
            if name != "diff":
                child.add_argument(
                    "--approve",
                    required=True,
                    help="exact action-bound token printed by plan",
                )
            child.set_defaults(handler=deployment_action)
        status_parser = sub.add_parser(
            "status",
            help="read profile, running system and generation history without mutation",
        )
        status_parser.add_argument("--target", required=True)
        status_parser.set_defaults(handler=status)
    return parser


def main(argv=None):
    os.umask(0o077)
    argv = sys.argv[1:] if argv is None else argv
    require(
        argv and argv[0] in {"deploymentctl", "pki-admin", "forgejo-admin"},
        "invoke through a packaged command",
    )
    parser = parser_for(argv[0])
    args = parser.parse_args(argv[1:])
    try:
        args.handler(args)
    except (
        Refusal,
        OSError,
        ValueError,
        TypeError,
        KeyError,
        yaml.YAMLError,
        InvalidSignature,
        UnsupportedAlgorithm,
        http.client.HTTPException,
        x509.ExtensionNotFound,
        x509.DuplicateExtension,
    ) as error:
        # Cryptographic libraries may embed input snippets in parse errors. Never
        # print arbitrary exception messages or tracebacks from secret operations.
        message = (
            str(error)
            if isinstance(error, Refusal)
            else type(error).__name__ + ": operation refused"
        )
        print(f"{args.program}: {message}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
