#!/usr/bin/env python3
"""Offline OpenSSL authority. Private state is explicit and never a publication directory."""

import argparse
import contextlib
import datetime as dt
import fcntl
import hashlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import uuid


class Failure(Exception):
    pass


def require(condition, message):
    if not condition:
        raise Failure(message)


def run(args, *, data=None, fds=()):
    result = subprocess.run(
        args,
        input=data,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        pass_fds=fds,
        check=False,
    )
    if result.returncode:
        # Do not echo subprocess input, arguments, key contents, or diagnostics.
        raise Failure(
            f"{Path(args[0]).name} {args[1]} failed (exit {result.returncode})"
        )
    return result.stdout


def openssl(*args, data=None, password=None):
    fds = ()
    if password and password.startswith("fd:"):
        fds = (int(password[3:]),)
        os.lseek(fds[0], 0, os.SEEK_SET)
    return run(["openssl", *map(str, args)], data=data, fds=fds)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def encoded(value):
    return (json.dumps(value, sort_keys=True, indent=2) + "\n").encode()


def save(path, data, mode=0o600):
    path = Path(path)
    with path.open("xb") as output:
        os.fchmod(output.fileno(), mode)
        output.write(data)
        output.flush()
        os.fsync(output.fileno())


def replace_json(path, value):
    path = Path(path)
    temp = path.with_name(path.name + ".next")
    save(temp, encoded(value))
    os.replace(temp, path)


def sync_directory(path):
    fd = os.open(path, os.O_RDONLY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def public_write(path, content):
    path = Path(path).absolute()
    require(
        not path.exists() and not path.is_symlink(), f"output already exists: {path}"
    )
    require(path.parent.is_dir(), "output parent must exist")
    with tempfile.NamedTemporaryFile(
        dir=path.parent, prefix=".root-ca-", delete=False
    ) as output:
        temporary = Path(output.name)
        try:
            os.fchmod(output.fileno(), 0o644)
            output.write(content)
            output.flush()
            os.fsync(output.fileno())
            os.link(temporary, path)  # no clobber, including a concurrent creator
            sync_directory(path.parent)
        finally:
            temporary.unlink(missing_ok=True)


def certificate(path):
    return openssl("x509", "-in", path, "-outform", "DER")


def fingerprint(path):
    return digest(certificate(path))


def expiry(path):
    value = (
        openssl("x509", "-in", path, "-noout", "-enddate")
        .decode()
        .strip()
        .split("=", 1)[1]
    )
    return dt.datetime.strptime(value, "%b %d %H:%M:%S %Y %Z").replace(
        tzinfo=dt.timezone.utc
    )


def utcnow():
    return dt.datetime.now(dt.timezone.utc)


def serial(path):
    return (
        openssl("x509", "-in", path, "-noout", "-serial")
        .decode()
        .strip()
        .split("=", 1)[1]
        .upper()
        .lstrip("0")
        or "0"
    )


def normalize_serial(value):
    require(bool(re.fullmatch(r"[0-9A-Fa-f]+", value)), "serial must be hexadecimal")
    return value.upper().lstrip("0") or "0"


def check_root(cert):
    openssl("verify", "-no_check_time", "-CAfile", cert, "-check_ss_sig", cert)
    text = openssl("x509", "-in", cert, "-noout", "-text").decode()
    require(
        "CA:TRUE" in text and "Certificate Sign" in text and "CRL Sign" in text,
        "root must have CA, certificate signing, and CRL signing extensions",
    )
    names = (
        openssl(
            "x509", "-in", cert, "-noout", "-subject", "-issuer", "-nameopt", "RFC2253"
        )
        .decode()
        .splitlines()
    )
    require(
        names[0].split("=", 1)[1] == names[1].split("=", 1)[1],
        "root must be self-issued",
    )


def check_key(key, cert, password):
    first_line = Path(key).read_bytes().splitlines()
    require(
        first_line and first_line[0] == b"-----BEGIN ENCRYPTED PRIVATE KEY-----",
        "root key must be encrypted PKCS#8 PEM",
    )
    pubkey = openssl(
        "pkey",
        "-in",
        key,
        "-passin",
        password,
        "-pubout",
        "-outform",
        "DER",
        password=password,
    )
    certpub = openssl("x509", "-in", cert, "-pubkey", "-noout")
    require(
        pubkey == openssl("pkey", "-pubin", "-outform", "DER", data=certpub),
        "key does not match root certificate",
    )


def password_arg(args):
    if getattr(args, "passphrase_file", None):
        path = Path(args.passphrase_file).absolute()
        require(path.is_file(), "passphrase file is missing")
        require(
            path.stat().st_mode & 0o077 == 0,
            "passphrase file must not be group/world accessible",
        )
        first_line = path.read_bytes().splitlines()
        require(
            first_line and first_line[0].strip(),
            "passphrase first line must not be empty",
        )
        return f"file:{path}"
    fd = getattr(args, "passphrase_fd", None)
    require(
        fd is not None, "an explicit --passphrase-file or --passphrase-fd is required"
    )
    # Rewind this inherited descriptor before each OpenSSL invocation.
    # Pipes are deliberately rejected: signing requires multiple crypto operations.
    require(os.lseek(fd, 0, os.SEEK_CUR) >= 0, "passphrase FD must be seekable")
    first_line = os.pread(fd, 4096, 0).splitlines()
    require(
        first_line and first_line[0].strip(), "passphrase first line must not be empty"
    )
    return f"fd:{fd}"


class State:
    def __init__(self, path):
        require(not Path(path).is_symlink(), "state must not be a symlink")
        self.path = Path(path).resolve()
        require(self.path != Path("/"), "state cannot be filesystem root")
        require(
            not str(self.path).startswith("/nix/store/"),
            "state cannot be in the Nix store",
        )
        require(not self.path.is_symlink(), "state must not be a symlink")
        # Refuse a checkout, including git worktrees; ancestors are checked without reading secrets.
        require(
            not any((p / ".git").exists() for p in [self.path, *self.path.parents]),
            "private state cannot be inside a Git checkout",
        )
        self.meta = None
        self.generation = None
        self.fresh_created = False

    @contextlib.contextmanager
    def locked(self, fresh=False):
        if fresh:
            require(
                not self.path.exists(), "state must be a fresh nonexistent directory"
            )
            self.path.mkdir(mode=0o700, parents=False)
            self.fresh_created = True
        require(self.path.is_dir(), "state directory does not exist")
        require(
            self.path.stat().st_uid == os.getuid()
            and self.path.stat().st_mode & 0o077 == 0,
            "state must be owned by current user and mode 0700",
        )
        fd = os.open(
            self.path / "lock",
            os.O_RDWR | os.O_CREAT | getattr(os, "O_NOFOLLOW", 0),
            0o600,
        )
        try:
            try:
                fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError as error:
                raise Failure("authority is locked by another operation") from error
            if (self.path / "current").is_symlink():
                target = os.readlink(self.path / "current")
                require(
                    bool(re.fullmatch(r"generations/[0-9]{12}", target)),
                    "invalid generation pointer",
                )
                self.generation = self.path / target
                self.meta = json.loads((self.generation / "manifest.json").read_text())
                require(
                    self.meta["generation"] == int(Path(target).name),
                    "generation metadata mismatch",
                )
            elif not fresh:
                raise Failure(
                    "state has no committed generation; preserve it for recovery or use a fresh directory"
                )
            yield self
        finally:
            os.close(fd)

    @contextlib.contextmanager
    def transaction(self):
        stage = Path(tempfile.mkdtemp(prefix=".transaction-", dir=self.path))
        try:
            if self.generation:
                shutil.copytree(self.generation, stage, dirs_exist_ok=True)
                meta = json.loads((stage / "manifest.json").read_text())
                meta["generation"] += 1
            else:
                meta = {
                    "format": 1,
                    "generation": 1,
                    "lineage": str(uuid.uuid4()),
                    "active": None,
                    "authorities": {},
                }
            yield stage, meta
            replace_json(stage / "manifest.json", meta)
            # Sync every copied/updated database file before the pointer is made durable.
            for base, _, files in os.walk(stage):
                for name in files:
                    with (Path(base) / name).open("rb") as stream:
                        os.fsync(stream.fileno())
                sync_directory(base)
            generations = self.path / "generations"
            generations.mkdir(exist_ok=True, mode=0o700)
            destination = generations / f"{meta['generation']:012d}"
            # A crash can leave an unreferenced generation; never reuse its number.
            while destination.exists():
                meta["generation"] += 1
                destination = generations / f"{meta['generation']:012d}"
            replace_json(stage / "manifest.json", meta)
            sync_directory(stage)
            os.rename(stage, destination)
            sync_directory(generations)
            link = self.path / f".current-{uuid.uuid4().hex}"
            os.symlink(str(destination.relative_to(self.path)), link)
            os.replace(link, self.path / "current")
            sync_directory(self.path)
            self.generation, self.meta = destination, meta
        finally:
            if stage.exists():
                shutil.rmtree(stage)

    def authority(self, requested=None, stage=None, meta=None):
        meta = meta or self.meta
        identity = requested or meta["active"]
        require(identity in meta["authorities"], "unknown authority fingerprint")
        return (
            (stage or self.generation) / "authorities" / identity,
            meta["authorities"][identity],
            identity,
        )


def configuration(authority):
    # Only controlled, temporary paths reach the OpenSSL config. Quote paths for spaces.
    directory = str(authority)
    require(
        not any(c in directory for c in '\n\r"$'), "unsupported character in state path"
    )
    return f'''[ ca ]
default_ca = authority
[ authority ]
dir = "{directory}"
database = $dir/index.txt
new_certs_dir = $dir/newcerts
certificate = $dir/root_ca.crt
private_key = $dir/root.key
serial = $dir/serial
crlnumber = $dir/crlnumber
default_md = sha256
default_days = 365
default_crl_days = 30
policy = subject_policy
unique_subject = no
copy_extensions = none
x509_extensions = intermediate
[ subject_policy ]
countryName = optional
stateOrProvinceName = optional
localityName = optional
organizationName = optional
organizationalUnitName = optional
commonName = supplied
emailAddress = optional
[ intermediate ]
basicConstraints = critical,CA:true,pathlen:0
keyUsage = critical,keyCertSign,cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
[ root ]
basicConstraints = critical,CA:true
keyUsage = critical,keyCertSign,cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always
[ req ]
distinguished_name = subject_policy
'''


@contextlib.contextmanager
def ca_config(authority):
    path = authority / "openssl.cnf"
    save(path, configuration(authority).encode())
    try:
        yield path
    finally:
        path.unlink(missing_ok=True)


def database(authority):
    (authority / "newcerts").mkdir(mode=0o700)
    save(authority / "index.txt", b"")
    save(authority / "index.txt.attr", b"unique_subject = no\n")
    # Random initial serial is subsequently advanced exclusively by openssl ca.
    save(authority / "serial", (os.urandom(16).hex().upper() + "\n").encode())
    save(authority / "crlnumber", b"01\n")


def new_authority(stage, meta, args, password):
    require(args.days > 0, "validity days must be positive")
    require(args.bits >= 2048, "RSA keys must be at least 2048 bits")
    work = stage / "new-authority"
    work.mkdir(mode=0o700)
    openssl(
        "genpkey",
        "-algorithm",
        "RSA",
        "-pkeyopt",
        f"rsa_keygen_bits:{args.bits}",
        "-aes-256-cbc",
        "-pass",
        password,
        "-out",
        work / "root.key",
        password=password,
    )
    with ca_config(work) as config:
        openssl(
            "req",
            "-new",
            "-x509",
            "-sha256",
            "-key",
            work / "root.key",
            "-passin",
            password,
            "-days",
            args.days,
            "-subj",
            args.subject,
            "-config",
            config,
            "-extensions",
            "root",
            "-out",
            work / "root_ca.crt",
            password=password,
        )
    check_root(work / "root_ca.crt")
    identity = fingerprint(work / "root_ca.crt")
    database(work)
    (stage / "authorities").mkdir(exist_ok=True, mode=0o700)
    os.rename(work, stage / "authorities" / identity)
    meta["authorities"][identity] = {
        "status": "active",
        "history": "complete",
        "origin": "generated",
    }
    meta["active"] = identity
    return identity


def assert_signing(authority, record, password):
    require(record["status"] != "retired", "authority is retired")
    require(
        (authority / "root.key").is_file(), "certificate-only authority cannot sign"
    )
    require(expiry(authority / "root_ca.crt") > utcnow(), "root has expired")
    check_key(authority / "root.key", authority / "root_ca.crt", password)


def issue_crl(authority, record, password, days=30):
    assert_signing(authority, record, password)
    require(days > 0, "CRL days must be positive")
    end = min(utcnow() + dt.timedelta(days=days), expiry(authority / "root_ca.crt"))
    with ca_config(authority) as config:
        openssl(
            "ca",
            "-batch",
            "-config",
            config,
            "-gencrl",
            "-crl_lastupdate",
            utcnow().strftime("%Y%m%d%H%M%SZ"),
            "-crl_nextupdate",
            end.strftime("%Y%m%d%H%M%SZ"),
            "-passin",
            password,
            "-out",
            authority / "root.crl",
            password=password,
        )
    verify_crl(authority / "root.crl", authority / "root_ca.crt")


def verify_crl(crl, cert):
    openssl("crl", "-in", crl, "-noout", "-verify", "-CAfile", cert)
    dates = (
        openssl("crl", "-in", crl, "-noout", "-lastupdate", "-nextupdate")
        .decode()
        .splitlines()
    )
    parsed = [
        dt.datetime.strptime(row.split("=", 1)[1], "%b %d %H:%M:%S %Y %Z").replace(
            tzinfo=dt.timezone.utc
        )
        for row in dates
    ]
    require(parsed[0] <= utcnow() < parsed[1], "CRL is not currently valid")


def approval(state, args):
    authority, record, identity = state.authority(args.authority)
    csr = Path(args.csr).absolute()
    openssl("req", "-in", csr, "-verify", "-noout")
    require(args.days > 0, "validity days must be positive")
    require(bool(args.change.strip()), "change description must not be empty")
    plan = {
        "rootFingerprint": identity,
        "csrSha256": digest(openssl("req", "-in", csr, "-outform", "DER")),
        "profile": "intermediate-ca-pathlen0-sha256-v1",
        "days": args.days,
        "change": args.change,
        "replaces": normalize_serial(args.replaces) if args.replaces else None,
        "generation": state.meta["generation"],
        "lineage": state.meta["lineage"],
    }
    return digest(encoded(plan)), plan


def find_issued(authority, value):
    wanted = normalize_serial(value)
    matches = [
        p
        for p in (authority / "newcerts").glob("*.pem")
        if normalize_serial(p.stem) == wanted
    ]
    require(
        len(matches) == 1, "serial is not an archived certificate in this authority"
    )
    cert = matches[0]
    require(serial(cert) == wanted, "archived serial mismatch")
    openssl("verify", "-no_check_time", "-CAfile", authority / "root_ca.crt", cert)
    return cert


def lifecycle_approval(state, args, identity):
    plan = {
        "action": args.command,
        "rootFingerprint": identity,
        "generation": state.meta["generation"],
        "lineage": state.meta["lineage"],
        "change": args.change,
    }
    if args.command == "rollover":
        plan.update(subject=args.subject, days=args.days, bits=args.bits)
    return digest(encoded(plan))


def revocation_approval(state, args):
    authority, _, identity = state.authority(args.authority)
    cert = find_issued(authority, args.serial)
    require(args.change.strip(), "change description must not be empty")
    plan = {
        "action": "revoke",
        "rootFingerprint": identity,
        "serial": serial(cert),
        "certificateSha256": fingerprint(cert),
        "reason": args.reason,
        "crlDays": args.crl_days,
        "change": args.change,
        "generation": state.meta["generation"],
        "lineage": state.meta["lineage"],
    }
    return digest(encoded(plan)), plan


def export_public(state, args):
    output = Path(args.output).resolve()
    require(
        not output.exists() and not output.is_symlink(), "export output must not exist"
    )
    require(output.parent.is_dir(), "export parent must exist")
    require(
        state.path not in [output, *output.parents],
        "publication cannot be inside private state",
    )
    work = Path(tempfile.mkdtemp(prefix=".root-ca-public-", dir=output.parent))
    try:
        authority, selected, identity = state.authority(args.authority)
        require(
            selected["status"] != "retired",
            "retired authorities cannot be published as trust roots",
        )
        save(work / "root_ca.crt", (authority / "root_ca.crt").read_bytes(), 0o644)
        if (authority / "root.crl").exists():
            verify_crl(authority / "root.crl", authority / "root_ca.crt")
            save(work / "root.crl", (authority / "root.crl").read_bytes(), 0o644)
        roots = work / "roots"
        roots.mkdir(mode=0o755)
        for root, record in state.meta["authorities"].items():
            if record["status"] != "retired":
                save(
                    roots / f"{root}.crt",
                    (
                        state.generation / "authorities" / root / "root_ca.crt"
                    ).read_bytes(),
                    0o644,
                )
        if args.serial:
            save(
                work / "intermediate.crt",
                find_issued(authority, args.serial).read_bytes(),
                0o644,
            )
        manifest = dict(state.meta, exportedAuthority=identity)
        save(work / "manifest.json", encoded(manifest), 0o644)
        os.chmod(work, 0o755)
        os.rename(work, output)
        sync_directory(output.parent)
    finally:
        if work.exists():
            shutil.rmtree(work)


def check_database(authority):
    require(
        all(
            (authority / name).is_file()
            for name in ("serial", "crlnumber", "index.txt")
        ),
        "incomplete OpenSSL CA database",
    )
    for name in ("serial", "crlnumber"):
        normalize_serial((authority / name).read_text().strip())
    seen = set()
    for row in (authority / "index.txt").read_text().splitlines():
        fields = row.split("\t")
        require(
            len(fields) == 6 and fields[0] in ("V", "R", "E"), "invalid CA index row"
        )
        value = normalize_serial(fields[3])
        require(value not in seen, "duplicate CA index serial")
        seen.add(value)
        find_issued(authority, value)
    require(
        int((authority / "serial").read_text().strip(), 16)
        > max([int(s, 16) for s in seen], default=-1),
        "CA serial counter does not exceed historical serials",
    )


def import_authority(state, args):
    cert = Path(args.certificate).absolute()
    check_root(cert)
    identity = fingerprint(cert)
    require(
        args.history_directory or args.acknowledge_incomplete_history,
        "import without CA database requires --acknowledge-incomplete-history; historical revocation is unknown",
    )
    password = password_arg(args) if args.key else None
    if args.key:
        check_key(args.key, cert, password)
    with state.transaction() as (stage, meta):
        authority = stage / "authorities" / identity
        authority.mkdir(parents=True, mode=0o700)
        save(authority / "root_ca.crt", openssl("x509", "-in", cert, "-outform", "PEM"))
        if args.key:
            save(authority / "root.key", Path(args.key).read_bytes())
        if args.history_directory:
            source = Path(args.history_directory)
            for name in ("index.txt", "serial", "crlnumber"):
                save(authority / name, (source / name).read_bytes())
            save(authority / "index.txt.attr", b"unique_subject = no\n")
            (authority / "newcerts").mkdir(mode=0o700)
            for archived in (source / "newcerts").glob("*.pem"):
                require(
                    not archived.is_symlink(),
                    "historical archive must not contain symlinks",
                )
                save(authority / "newcerts" / archived.name, archived.read_bytes())
            if (source / "root.crl").exists():
                verify_crl(source / "root.crl", cert)
                save(authority / "root.crl", (source / "root.crl").read_bytes())
            check_database(authority)
        else:
            database(authority)
        meta["active"] = identity
        meta["authorities"][identity] = {
            "status": "active",
            "history": "complete" if args.history_directory else "incomplete",
            "origin": "imported",
            "historicalRevocationUnknown": not bool(args.history_directory),
        }


def backup(state, args):
    require(bool(args.recipient), "at least one age recipient is required")
    output = Path(args.output).resolve()
    require(not output.exists(), "backup output already exists")
    require(
        state.path not in [output, *output.parents],
        "backup cannot be stored inside authority state",
    )
    # Only ciphertext reaches disk: tar streams directly into age's stdin.
    with tempfile.NamedTemporaryFile(
        dir=output.parent, prefix=".root-ca-backup-", delete=False
    ) as encrypted:
        temporary = Path(encrypted.name)
        process = None
        try:
            process = subprocess.Popen(
                [
                    "age",
                    *[
                        item
                        for recipient in args.recipient
                        for item in ("-r", recipient)
                    ],
                ],
                stdin=subprocess.PIPE,
                stdout=encrypted,
                stderr=subprocess.PIPE,
            )
            with tarfile.open(fileobj=process.stdin, mode="w|") as archive:
                for base, dirs, files in os.walk(state.generation):
                    dirs.sort()
                    for name in sorted(files):
                        path = Path(base) / name
                        require(not path.is_symlink(), "state cannot contain symlinks")
                        archive.add(
                            path,
                            arcname=str(path.relative_to(state.generation)),
                            recursive=False,
                        )
            process.stdin.close()
            process.stderr.read()
            require(process.wait() == 0, "age encryption failed")
            encrypted.flush()
            os.fsync(encrypted.fileno())
            encrypted.seek(0)
            checksum = hashlib.file_digest(encrypted, "sha256").hexdigest()
            os.link(temporary, output)
            sync_directory(output.parent)
        finally:
            if process and process.poll() is None:
                process.kill()
                process.wait()
            temporary.unlink(missing_ok=True)
    print(
        json.dumps(
            {
                "path": str(output),
                "sha256": checksum,
                "generation": state.meta["generation"],
                "active": state.meta["active"],
                "authorities": sorted(state.meta["authorities"]),
            }
        )
    )


def restore(args):
    state = State(args.state)
    require(args.minimum_generation >= 1, "trusted minimum generation must be positive")
    require(
        bool(re.fullmatch(r"[0-9a-f]{64}", args.expected_fingerprint)),
        "expected fingerprint must be lowercase SHA-256 hex",
    )
    require(
        bool(re.fullmatch(r"[0-9a-f]{64}", args.expected_sha256)),
        "expected backup digest must be lowercase SHA-256 hex",
    )
    # An age recipient is public: encryption alone does not authenticate the sender.
    # Pin the exact ciphertext against a separately retained trusted backup record.
    encrypted = Path(args.input).read_bytes()
    require(
        digest(encrypted) == args.expected_sha256,
        "backup ciphertext does not match trusted SHA-256",
    )
    payload = run(
        ["age", "--decrypt", "-i", str(Path(args.identity).absolute())], data=encrypted
    )
    members = {}
    with tarfile.open(fileobj=io.BytesIO(payload), mode="r:") as archive:
        for member in archive:
            path = Path(member.name)
            require(
                member.isfile() and not path.is_absolute() and ".." not in path.parts,
                "backup contains unsafe archive member",
            )
            require(member.name not in members, "backup contains duplicate member")
            require(
                member.size <= 64 * 1024 * 1024, "backup member exceeds safety limit"
            )
            members[member.name] = archive.extractfile(member).read()
    require("manifest.json" in members, "backup has no manifest")
    meta = json.loads(members["manifest.json"])
    require(
        meta["format"] == 1 and meta["generation"] >= args.minimum_generation,
        "backup is older than trusted minimum generation",
    )
    require(
        args.expected_fingerprint in meta["authorities"],
        "backup authority fingerprint mismatch",
    )
    require(
        meta["active"] is None or meta["active"] in meta["authorities"],
        "backup active authority is unknown",
    )
    require(
        meta["active"] is None or args.expected_fingerprint == meta["active"],
        "expected fingerprint does not match backup active authority",
    )
    if args.reference_state:
        reference = State(args.reference_state)
        with reference.locked():
            require(
                meta["lineage"] == reference.meta["lineage"],
                "backup lineage differs from reference",
            )
            require(
                meta["generation"] >= reference.meta["generation"],
                "backup is stale relative to reference state",
            )
    try:
        with state.locked(fresh=True):
            with state.transaction() as (stage, fresh):
                for name, content in members.items():
                    path = stage / name
                    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
                    save(path, content)
                fresh.clear()
                fresh.update(meta)
                # Restoring itself advances the high-water mark.
                fresh["generation"] += 1
                for identity in fresh["authorities"]:
                    authority = stage / "authorities" / identity
                    require(
                        fingerprint(authority / "root_ca.crt") == identity,
                        "restored root fingerprint mismatch",
                    )
                    check_root(authority / "root_ca.crt")
                    check_database(authority)
                    if (authority / "root.crl").exists():
                        # An expired CRL remains history and must be refreshed before publication.
                        openssl(
                            "crl",
                            "-in",
                            authority / "root.crl",
                            "-noout",
                            "-verify",
                            "-CAfile",
                            authority / "root_ca.crt",
                        )
    except Exception:
        # Only remove our own uncommitted fresh state, never a pre-existing directory.
        if state.fresh_created and not (state.path / "current").exists():
            shutil.rmtree(state.path)
        raise
    print(
        json.dumps(
            {
                "restoredGeneration": state.meta["generation"],
                "active": state.meta["active"],
            }
        )
    )


def dispatch(args):
    if args.command == "restore":
        restore(args)
        return
    state = State(args.state)
    fresh = args.command in ("init", "import")
    with state.locked(fresh=fresh):
        if args.command == "init":
            with state.transaction() as (stage, meta):
                new_authority(stage, meta, args, password_arg(args))
            print(state.meta["active"])
        elif args.command == "import":
            import_authority(state, args)
            print(state.meta["active"])
        elif args.command == "status":
            result = dict(state.meta)
            result["signingKeysPresent"] = {
                identity: (
                    state.generation / "authorities" / identity / "root.key"
                ).exists()
                for identity in state.meta["authorities"]
            }
            print(json.dumps(result, sort_keys=True, indent=2))
        elif args.command == "fingerprint":
            print(state.authority(args.authority)[2])
        elif args.command == "export":
            export_public(state, args)
        elif args.command == "backup":
            backup(state, args)
        elif args.command == "verify":
            authority, _, _ = state.authority(args.authority)
            check_root(authority / "root_ca.crt")
            require(expiry(authority / "root_ca.crt") > utcnow(), "root has expired")
            check_database(authority)
            if args.certificate:
                command = ["verify", "-CAfile", authority / "root_ca.crt"]
                if args.crl:
                    verify_crl(args.crl, authority / "root_ca.crt")
                    command += ["-crl_check", "-CRLfile", args.crl]
                openssl(*command, args.certificate)
            print("verified")
        elif args.command == "intermediate":
            if args.operation == "plan":
                token, plan = approval(state, args)
                print(json.dumps(dict(plan, approval=token), sort_keys=True, indent=2))
                return
            if args.operation == "revoke":
                token, plan = revocation_approval(state, args)
                if args.plan:
                    print(
                        json.dumps(dict(plan, approval=token), sort_keys=True, indent=2)
                    )
                    return
                require(
                    args.approval == token,
                    "revocation approval does not match authority, certificate, reason, change, or generation",
                )
            password = password_arg(args)
            if args.operation in ("sign", "rotate"):
                require(
                    args.operation != "rotate" or args.replaces,
                    "rotate requires --replaces SERIAL; overlap is retained until explicit revoke",
                )
                require(
                    args.operation != "sign" or not args.replaces,
                    "use rotate with --replaces",
                )
                token, plan = approval(state, args)
                require(
                    args.approval == token,
                    "approval does not match root, CSR, profile, change, or current generation",
                )
                output = Path(args.output).resolve()
                require(
                    not output.exists()
                    and not output.is_symlink()
                    and output.parent.is_dir(),
                    "certificate output must be new with existing parent",
                )
                require(
                    state.path not in [output, *output.parents],
                    "certificate output cannot be inside state",
                )
                with state.transaction() as (stage, meta):
                    authority, record, _ = state.authority(args.authority, stage, meta)
                    assert_signing(authority, record, password)
                    if args.replaces:
                        find_issued(authority, args.replaces)
                    end = min(
                        utcnow() + dt.timedelta(days=args.days),
                        expiry(authority / "root_ca.crt"),
                    )
                    csr = authority / "request.csr"
                    # Use the exact CSR bytes approved above, avoiding a path-replacement race.
                    save(csr, openssl("req", "-in", args.csr, "-outform", "PEM"))
                    require(
                        digest(openssl("req", "-in", csr, "-outform", "DER"))
                        == plan["csrSha256"],
                        "CSR changed after approval",
                    )
                    issued = authority / "issued.crt"
                    with ca_config(authority) as config:
                        openssl(
                            "ca",
                            "-batch",
                            "-notext",
                            "-config",
                            config,
                            "-passin",
                            password,
                            "-in",
                            csr,
                            "-enddate",
                            end.strftime("%Y%m%d%H%M%SZ"),
                            "-extensions",
                            "intermediate",
                            "-out",
                            issued,
                            password=password,
                        )
                    openssl("verify", "-CAfile", authority / "root_ca.crt", issued)
                    value = serial(issued)
                    content = issued.read_bytes()
                    csr.unlink()
                    issued.unlink()
                    audit = authority / "approvals"
                    audit.mkdir(exist_ok=True, mode=0o700)
                    save(
                        audit / f"{value}.json",
                        encoded(dict(plan, approval=token, serial=value)),
                    )
                try:
                    public_write(output, content)
                except Exception as error:
                    raise Failure(
                        f"certificate {value} committed; output failed; recover with export --serial {value} --output NEW_DIR"
                    ) from error
                print(
                    json.dumps(
                        {"serial": value, "generation": state.meta["generation"]}
                    )
                )
            else:
                with state.transaction() as (stage, meta):
                    authority, record, _ = state.authority(args.authority, stage, meta)
                    assert_signing(authority, record, password)
                    cert = find_issued(authority, args.serial)
                    with ca_config(authority) as config:
                        openssl(
                            "ca",
                            "-batch",
                            "-config",
                            config,
                            "-passin",
                            password,
                            "-revoke",
                            cert,
                            "-crl_reason",
                            args.reason,
                            password=password,
                        )
                    issue_crl(authority, record, password, args.crl_days)
                    audit = authority / "approvals"
                    audit.mkdir(exist_ok=True, mode=0o700)
                    save(
                        audit / f"revoke-{plan['serial']}.json",
                        encoded(dict(plan, approval=token)),
                    )
        elif args.command == "crl":
            if args.operation == "verify":
                authority, _, _ = state.authority(args.authority)
                verify_crl(
                    args.input or authority / "root.crl", authority / "root_ca.crt"
                )
                print("verified")
            else:
                with state.transaction() as (stage, meta):
                    authority, record, _ = state.authority(args.authority, stage, meta)
                    issue_crl(authority, record, password_arg(args), args.days)
        elif args.command in ("rollover", "retire"):
            _, record, identity = state.authority(args.authority)
            require(record["status"] != "retired", "authority is already retired")
            require(args.change.strip(), "change description must not be empty")
            token = lifecycle_approval(state, args, identity)
            if args.plan:
                print(
                    json.dumps(
                        {
                            "action": args.command,
                            "rootFingerprint": identity,
                            "generation": state.meta["generation"],
                            "approval": token,
                        }
                    )
                )
                return
            require(
                args.approval == token,
                "lifecycle approval does not match authority and generation",
            )
            if args.command == "rollover":
                require(
                    identity == state.meta["active"],
                    "rollover must select active authority",
                )
                with state.transaction() as (stage, meta):
                    meta["authorities"][identity]["status"] = "overlap"
                    successor = new_authority(stage, meta, args, password_arg(args))
                    meta["authorities"][identity]["successor"] = successor
                    meta["authorities"][successor]["predecessor"] = identity
                    meta["authorities"][identity]["rolloverApproval"] = token
                    meta["authorities"][identity]["rolloverChange"] = args.change
                print(successor)
            else:
                require(
                    args.acknowledge_external_trust_removal,
                    "retirement requires --acknowledge-external-trust-removal; this tool cannot remove remote trust or erase backups",
                )
                with state.transaction() as (stage, meta):
                    authority, target, _ = state.authority(identity, stage, meta)
                    target["status"] = "retired"
                    target["retiredAt"] = utcnow().isoformat()
                    target["externalTrustRemovalAcknowledged"] = True
                    target["retirementApproval"] = token
                    target["retirementChange"] = args.change
                    if meta["active"] == identity:
                        meta["active"] = None
                print(
                    "retired locally; remote trust and historical backups require separate operator action"
                )


def parser():
    cli = argparse.ArgumentParser(
        description=__doc__,
        epilog="State must be outside Git/store, private mode 0700. Outputs never overwrite. Use --help on each subcommand.",
    )
    cli.add_argument(
        "--state", required=True, help="explicit private authority directory"
    )
    cli.add_argument(
        "--authority",
        help="SHA-256 root fingerprint (default active root; selects overlap roots for CRL/revocation)",
    )
    commands = cli.add_subparsers(dest="command", required=True)

    def password(p):
        group = p.add_mutually_exclusive_group()
        group.add_argument(
            "--passphrase-file", help="private runtime file; never a literal password"
        )
        group.add_argument(
            "--passphrase-fd", type=int, help="inherited seekable runtime descriptor"
        )

    def generation(p):
        p.add_argument(
            "--subject",
            required=True,
            help="OpenSSL subject, for example /CN=Offline Root",
        )
        p.add_argument("--days", type=int, default=3650)
        p.add_argument("--bits", type=int, default=4096)
        password(p)

    generation(
        commands.add_parser(
            "init", help="create a new identity, only in a fresh state directory"
        )
    )
    imp = commands.add_parser(
        "import", help="import an existing root; never generates a replacement identity"
    )
    imp.add_argument("--certificate", required=True)
    imp.add_argument(
        "--key", help="encrypted PKCS#8 root key (omit for certificate-only state)"
    )
    imp.add_argument(
        "--history-directory",
        help="OpenSSL index.txt/serial/crlnumber/newcerts and optional root.crl",
    )
    imp.add_argument("--acknowledge-incomplete-history", action="store_true")
    password(imp)
    commands.add_parser("status")
    commands.add_parser("fingerprint")
    export = commands.add_parser(
        "export", help="atomically publish public files into a NEW directory"
    )
    export.add_argument("--output", required=True)
    export.add_argument(
        "--serial", help="also export a committed intermediate as intermediate.crt"
    )
    verify = commands.add_parser(
        "verify", help="verify root/database, and optionally an issued certificate/CRL"
    )
    verify.add_argument("--certificate")
    verify.add_argument("--crl")
    intermediates = commands.add_parser("intermediate").add_subparsers(
        dest="operation", required=True
    )
    for operation in ("plan", "sign", "rotate"):
        p = intermediates.add_parser(operation)
        p.add_argument("--csr", required=True)
        p.add_argument("--days", type=int, default=365)
        p.add_argument(
            "--change",
            required=True,
            help="approval-bound operator change/ticket description",
        )
        p.add_argument(
            "--replaces",
            help="prior serial; rotate retains overlap until explicit revoke",
        )
        if operation != "plan":
            p.add_argument(
                "--approval",
                required=True,
                help="approval digest from intermediate plan",
            )
            p.add_argument("--output", required=True)
            password(p)
    revoke = intermediates.add_parser(
        "revoke", help="revoke an archived intermediate and refresh CRL atomically"
    )
    revoke.add_argument("--serial", required=True)
    revoke.add_argument(
        "--reason",
        choices=(
            "unspecified",
            "keyCompromise",
            "CACompromise",
            "affiliationChanged",
            "superseded",
            "cessationOfOperation",
            "certificateHold",
        ),
        required=True,
    )
    revoke.add_argument("--crl-days", type=int, default=30)
    revoke.add_argument("--change", required=True)
    revoke.add_argument(
        "--plan",
        action="store_true",
        help="emit revocation approval without changing state",
    )
    revoke.add_argument("--approval")
    password(revoke)
    crls = commands.add_parser("crl").add_subparsers(dest="operation", required=True)
    crl = crls.add_parser(
        "issue", help="refresh signed CRL, with validity bounded by root"
    )
    crl.add_argument("--days", type=int, default=30)
    password(crl)
    crl = crls.add_parser("verify")
    crl.add_argument("--input", help="default selected authority's committed root.crl")
    back = commands.add_parser(
        "backup", help="stream complete active generation directly into age ciphertext"
    )
    back.add_argument("--output", required=True)
    back.add_argument(
        "--recipient", action="append", required=True, help="age recipient, repeatable"
    )
    rest = commands.add_parser(
        "restore",
        help="restore a trusted ciphertext snapshot into fresh state, with an external digest and high-water mark",
    )
    rest.add_argument("--input", required=True)
    rest.add_argument("--identity", required=True, help="runtime age identity file")
    rest.add_argument(
        "--minimum-generation",
        type=int,
        required=True,
        help="trusted latest generation from offline record, not the backup itself",
    )
    rest.add_argument("--expected-fingerprint", required=True)
    rest.add_argument(
        "--expected-sha256",
        required=True,
        help="trusted ciphertext digest retained separately when backup was created",
    )
    rest.add_argument(
        "--reference-state",
        help="also reject backups older than an existing same-lineage authority",
    )
    for operation in ("rollover", "retire"):
        p = commands.add_parser(operation)
        p.add_argument(
            "--plan",
            action="store_true",
            help="emit approval bound to authority and current generation",
        )
        p.add_argument("--approval")
        p.add_argument("--change", required=True)
        if operation == "rollover":
            p.add_argument("--subject")
            p.add_argument("--days", type=int, default=3650)
            p.add_argument("--bits", type=int, default=4096)
            password(p)
        else:
            p.add_argument("--acknowledge-external-trust-removal", action="store_true")
    return cli


def main():
    os.umask(0o077)
    try:
        args = parser().parse_args()
        if args.command == "rollover":
            require(args.subject, "rollover requires --subject, including for --plan")
        dispatch(args)
        return 0
    except (
        Failure,
        OSError,
        ValueError,
        KeyError,
        tarfile.TarError,
        BrokenPipeError,
    ) as error:
        print(f"root-ca: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
