"""Root-only consistent encrypted backup and approval-bound restore of corporate services."""

import argparse
import contextlib
import datetime
import fcntl
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import pwd
import shutil
import stat
import subprocess
import sys
import tarfile
import tempfile
import uuid


class MaintenanceError(Exception):
    pass


def require(condition, message):
    if not condition:
        raise MaintenanceError(message)


def digest(path):
    result = hashlib.sha256()
    with open(path, "rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            result.update(block)
    return result.hexdigest()


def private_file(path, label):
    require(os.path.isabs(path), f"{label} must be an absolute path")
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_CLOEXEC)
    info = os.fstat(fd)
    if not (
        stat.S_ISREG(info.st_mode) and info.st_uid == 0 and info.st_mode & 0o077 == 0
    ):
        os.close(fd)
        raise MaintenanceError(f"{label} must be a root-owned private regular file")
    return fd


def private_directory(path):
    path = Path(path)
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    info = path.lstat()
    require(
        stat.S_ISDIR(info.st_mode) and info.st_uid == 0 and info.st_mode & 0o077 == 0,
        "Maintenance directory must be root-owned mode0700, not a symlink",
    )
    return path


class Executor:
    def __init__(self, config):
        self.config = config
        self.tools = config["tools"]

    def run(self, command, **kwargs):
        # Never relay database, app.ini, key, password or subprocess diagnostics.
        return subprocess.run(
            command,
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            **kwargs,
        )

    def systemctl(self, *args):
        self.run([self.tools["systemctl"], *args])

    def active(self, unit):
        return (
            subprocess.run(
                [self.tools["systemctl"], "is-active", "--quiet", unit],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            ).returncode
            == 0
        )

    def pg(self, executable, *args):
        return [
            self.tools["runuser"],
            "-u",
            "postgres-forgejo",
            "--",
            self.tools["pgBin"] + "/" + executable,
            "--no-password",
            "-h",
            "/run/postgresql-forgejo",
            "-p",
            "5432",
            "-U",
            "forgejo-db-admin",
            *args,
        ]

    def sql(self, statement, database="postgres"):
        self.run(
            self.pg(
                "psql",
                "--no-psqlrc",
                "-v",
                "ON_ERROR_STOP=1",
                "-d",
                database,
                "-c",
                statement,
            )
        )

    def pki_check(self):
        self.run(self.config["pki"]["validationCommand"])
        require(
            self.active("step-ca.service"),
            "PKI materials validate but step-ca is not active",
        )
        print("PKI material and native service checks passed")

    def forgejo_doctor(self):
        cfg = self.config["forgejo"]
        self.run(
            self.pg(
                "psql",
                "--no-psqlrc",
                "-v",
                "ON_ERROR_STOP=1",
                "-d",
                "forgejo",
                "-c",
                "SELECT 1",
            )
        )
        require(self.active("forgejo.service"), "Forgejo is not active")
        self.run(
            [
                self.tools["runuser"],
                "-u",
                "forgejo",
                "--",
                cfg["binary"],
                "--work-path",
                cfg["stateDir"],
                "--custom-path",
                cfg["customDir"],
                "--config",
                cfg["customDir"] + "/conf/app.ini",
                "doctor",
                "check",
                "--all",
            ]
        )
        print("Forgejo doctor and dedicated PostgreSQL checks passed")

    @contextlib.contextmanager
    def stopped(self, service, restart_on_error=True):
        unit = "step-ca.service" if service == "pki" else "forgejo.service"
        was_active = self.active(unit)
        self.systemctl("stop", unit)
        completed = False
        try:
            yield
            completed = True
        finally:
            if was_active and (completed or restart_on_error):
                self.systemctl("start", unit)

    def manifest(self, service):
        cfg = self.config[service]
        return {
            "format": 1,
            "service": service,
            "hostname": self.config["hostname"],
            "domain": cfg["domain"],
            "created": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "postgres_major": 18 if service == "forgejo" else None,
            "forgejo_version": cfg.get("version"),
            "state_directory": cfg.get("stateDir", "/var/lib/step-ca"),
        }

    def backup(self, service, work):
        cfg = self.config[service]
        backup = cfg["backup"]
        require(
            backup["recipient"],
            "A public age recipient must be configured before backup",
        )
        destination = private_directory(backup["directory"])
        name = (
            service
            + "-"
            + datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
            + "-"
            + uuid.uuid4().hex
            + ".tar.age"
        )
        partial = destination / ("." + name + ".partial")
        final = destination / name
        manifest = self.manifest(service)
        state = Path(manifest["state_directory"])
        require(
            state.is_dir() and not state.is_symlink(),
            "Service state directory does not exist or is a symlink",
        )
        with self.stopped(service):
            if service == "pki":
                snapshot = work / "materials"
                snapshot.mkdir(mode=0o700)
                for key, path in cfg["materials"].items():
                    shutil.copyfile(path, snapshot / key)
                self.run(
                    cfg["validationCommand"] + ["--material-directory", str(snapshot)]
                )
                manifest["materials"] = {
                    key: digest(snapshot / key) for key in cfg["materials"]
                }
            else:
                require(
                    self.active("postgresql-forgejo.service"),
                    "Dedicated PostgreSQL service must be running",
                )
                dump = work / "database.dump"
                with dump.open("xb") as output:
                    command = self.pg(
                        "pg_dump",
                        "--format=custom",
                        "--no-owner",
                        "--no-acl",
                        "--dbname=forgejo",
                    )
                    subprocess.run(
                        command, stdout=output, stderr=subprocess.DEVNULL, check=True
                    )
                manifest["dump_sha256"] = digest(dump)
                snapshot = work / "external-secrets"
                snapshot.mkdir(mode=0o700)
                manifest["external_secrets"] = {}
                for index, path in enumerate(cfg["externalSecrets"]):
                    name = str(index)
                    shutil.copyfile(path, snapshot / name)
                    manifest["external_secrets"][name] = {
                        "path": path,
                        "sha256": digest(snapshot / name),
                    }
            manifest_path = work / "manifest.json"
            manifest_path.write_text(json.dumps(manifest, sort_keys=True))
            try:
                with partial.open("xb") as output:
                    encryption = subprocess.Popen(
                        [
                            self.tools["age"],
                            "--encrypt",
                            "--recipient",
                            backup["recipient"],
                        ],
                        stdin=subprocess.PIPE,
                        stdout=output,
                        stderr=subprocess.DEVNULL,
                    )
                    try:
                        with tarfile.open(
                            fileobj=encryption.stdin, mode="w|"
                        ) as archive:
                            archive.add(
                                manifest_path, arcname="manifest.json", recursive=False
                            )
                            archive.add(
                                state,
                                arcname="state",
                                recursive=True,
                                filter=self.backup_filter,
                            )
                            if service == "pki":
                                archive.add(
                                    snapshot, arcname="materials", recursive=True
                                )
                            else:
                                archive.add(
                                    dump, arcname="database.dump", recursive=False
                                )
                                archive.add(
                                    snapshot, arcname="external-secrets", recursive=True
                                )
                        encryption.stdin.close()
                        require(encryption.wait() == 0, "age encryption failed")
                    except BaseException:
                        encryption.kill()
                        encryption.wait()
                        raise
                    output.flush()
                    os.fsync(output.fileno())
                os.rename(partial, final)
            except BaseException:
                partial.unlink(missing_ok=True)
                raise
        print(final)

    @staticmethod
    def backup_filter(member):
        require(
            member.isfile() or member.isdir() or member.issym() or member.islnk(),
            "Service state contains a special file; refusing incomplete backup",
        )
        return member

    def unpack(self, archive_path, destination):
        # Extract manually: never follow a member symlink, create device nodes, trust
        # archive ownership, or use tarfile.extract's pathname semantics.
        seen = set()
        links = set()
        directory_modes = []
        with tarfile.open(archive_path, "r:") as archive:
            for member in archive:
                name = PurePosixPath(member.name)
                require(
                    not name.is_absolute()
                    and ".." not in name.parts
                    and name.parts
                    and member.name == name.as_posix()
                    and member.name not in seen,
                    "Unsafe, noncanonical or duplicate archive member",
                )
                require(
                    name.parts[0]
                    in {
                        "state",
                        "manifest.json",
                        "materials",
                        "database.dump",
                        "external-secrets",
                    },
                    "Unexpected archive member",
                )
                require(
                    not any(str(parent) in links for parent in name.parents),
                    "Archive traverses a symlink",
                )
                seen.add(member.name)
                target = destination.joinpath(*name.parts)
                target.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
                if member.isdir():
                    target.mkdir(exist_ok=True, mode=0o700)
                    directory_modes.append((target, member.mode & 0o777))
                elif member.isfile():
                    require(
                        member.size <= shutil.disk_usage(destination).free,
                        "Insufficient temporary storage",
                    )
                    with (
                        archive.extractfile(member) as source,
                        target.open("xb") as output,
                    ):
                        shutil.copyfileobj(source, output, 1024 * 1024)
                    target.chmod(member.mode & 0o777)
                elif member.issym():
                    os.symlink(member.linkname, target)
                    links.add(member.name)
                elif member.islnk():
                    source_name = PurePosixPath(member.linkname)
                    require(
                        not source_name.is_absolute()
                        and ".." not in source_name.parts
                        and member.linkname == source_name.as_posix()
                        and str(source_name) in seen
                        and str(source_name) not in links,
                        "Unsafe hardlink in archive",
                    )
                    source = destination.joinpath(*source_name.parts)
                    require(
                        source.is_file() and not source.is_symlink(),
                        "Invalid archive hardlink",
                    )
                    os.link(source, target, follow_symlinks=False)
                else:
                    raise MaintenanceError("Unsupported archive member")
        for target, mode in reversed(directory_modes):
            target.chmod(mode)
        require(
            (destination / "state").is_dir()
            and not (destination / "state").is_symlink(),
            "Missing archived state",
        )
        require(
            (destination / "manifest.json").is_file()
            and not (destination / "manifest.json").is_symlink(),
            "Missing manifest",
        )
        return json.loads((destination / "manifest.json").read_text())

    def restore(self, service, backup_path, approval_path, work):
        cfg = self.config[service]
        identity = cfg["backup"]["identityFile"]
        require(identity, "Restore requires a configured runtime age identity")
        # SOPS identities may be symlinks; resolve only the identity, then enforce ownership.
        identity_path = str(Path(identity).resolve(strict=True))
        identity_fd = private_file(identity_path, "Restore identity")
        os.close(identity_fd)
        require(
            os.path.isabs(backup_path) and os.path.isabs(approval_path),
            "Restore paths must be absolute",
        )
        backup_fd = private_file(backup_path, "Encrypted backup")
        approval_fd = private_file(approval_path, "Restore approval")
        try:
            with os.fdopen(approval_fd, "r") as source:
                approval = json.load(source)
                approval_stat = os.fstat(source.fileno())
            # Pin encrypted bytes before hashing/decrypting, avoiding path replacement races.
            encrypted = work / "input.age"
            with os.fdopen(backup_fd, "rb") as source, encrypted.open("xb") as output:
                shutil.copyfileobj(source, output, 1024 * 1024)
            require(
                approval
                == {
                    "service": service,
                    "sha256": digest(encrypted),
                    "action": "restore",
                },
                "Restore approval does not match service/action/encrypted backup hash",
            )
            plaintext = work / "archive.tar"
            with plaintext.open("xb") as output:
                subprocess.run(
                    [
                        self.tools["age"],
                        "--decrypt",
                        "--identity",
                        identity_path,
                        str(encrypted),
                    ],
                    stdout=output,
                    stderr=subprocess.DEVNULL,
                    check=True,
                )
            extracted = work / "extracted"
            extracted.mkdir(mode=0o700)
            manifest = self.unpack(plaintext, extracted)
            expected = self.manifest(service)
            for key in (
                "format",
                "service",
                "hostname",
                "domain",
                "postgres_major",
                "forgejo_version",
                "state_directory",
            ):
                require(
                    manifest.get(key) == expected[key],
                    "Backup identity, service, schema or version mismatch",
                )
            if service == "pki":
                require(
                    set(manifest.get("materials", {})) == set(cfg["materials"]),
                    "PKI material inventory mismatch",
                )
                for key, path in cfg["materials"].items():
                    archived = extracted / "materials" / key
                    require(
                        archived.is_file()
                        and not archived.is_symlink()
                        and digest(archived)
                        == manifest["materials"][key]
                        == digest(path),
                        "Restore requires the exact backed-up SOPS issuer material to be installed first",
                    )
                self.run(cfg["validationCommand"])
            else:
                require(
                    digest(extracted / "database.dump") == manifest.get("dump_sha256"),
                    "Database dump digest mismatch",
                )
                expected_paths = set(cfg["externalSecrets"])
                archived_paths = set()
                for key, item in manifest.get("external_secrets", {}).items():
                    require(key.isdecimal(), "Invalid secret inventory")
                    require(
                        item["path"] in expected_paths,
                        "Unexpected external secret path",
                    )
                    archived = extracted / "external-secrets" / key
                    archived_paths.add(item["path"])
                    require(
                        archived.is_file()
                        and not archived.is_symlink()
                        and digest(archived) == item["sha256"] == digest(item["path"]),
                        "Install matching external Forgejo SOPS secrets before restore",
                    )
                require(
                    archived_paths == expected_paths,
                    "External secret inventory mismatch",
                )
                self.run(
                    [
                        self.tools["pgBin"] + "/pg_restore",
                        "--list",
                        str(extracted / "database.dump"),
                    ]
                )
            current = os.stat(approval_path, follow_symlinks=False)
            require(
                (current.st_dev, current.st_ino)
                == (approval_stat.st_dev, approval_stat.st_ino),
                "Approval file changed",
            )
            os.unlink(approval_path)
            # A failed restore may also have failed its rollback. Never restart an
            # issuer or app automatically against an uncertain database/state pair.
            with self.stopped(service, restart_on_error=False):
                self.install_restore(service, extracted)
        finally:
            # Descriptors may already have been closed by fdopen; close only if needed.
            for fd in (backup_fd, approval_fd):
                with contextlib.suppress(OSError):
                    os.close(fd)
        print(
            "Restore completed; previous state retained in a root-private pre-restore directory"
        )

    def install_restore(self, service, extracted):
        cfg = self.config[service]
        state = Path(cfg.get("stateDir", "/var/lib/step-ca"))
        require(
            state.is_dir() and not state.is_symlink(),
            "Existing service state must be a real directory",
        )
        suffix = (
            datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d%H%M%S")
            + "_"
            + uuid.uuid4().hex[:8]
        )
        saved = state.with_name(state.name + ".pre-restore-" + suffix)
        staged = state.with_name(state.name + ".restore-" + suffix)
        account = pwd.getpwnam("step-ca" if service == "pki" else "forgejo")
        shutil.copytree(extracted / "state", staged, symlinks=True)
        for root, dirs, files in os.walk(staged, followlinks=False):
            os.chown(root, account.pw_uid, account.pw_gid, follow_symlinks=False)
            for name in dirs + files:
                os.chown(
                    os.path.join(root, name),
                    account.pw_uid,
                    account.pw_gid,
                    follow_symlinks=False,
                )
        staged.chmod(0o700 if service == "pki" else 0o750)
        renamed_db = False
        replaced_state = False
        old_database = "forgejo_pre_restore_" + suffix
        try:
            if service == "forgejo":
                require(
                    self.active("postgresql-forgejo.service"),
                    "Dedicated PostgreSQL must be running",
                )
                self.sql(
                    "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='forgejo' AND pid <> pg_backend_pid()"
                )
                self.sql('ALTER DATABASE forgejo RENAME TO "' + old_database + '"')
                renamed_db = True
                self.sql("CREATE DATABASE forgejo OWNER forgejo TEMPLATE template0")
                self.sql("REVOKE ALL ON DATABASE forgejo FROM PUBLIC")
                # pg_restore runs as DB admin but assigns restored objects to app role.
                with (extracted / "database.dump").open("rb") as source:
                    self.run(
                        self.pg(
                            "pg_restore",
                            "--exit-on-error",
                            "--single-transaction",
                            "--clean",
                            "--if-exists",
                            "--no-owner",
                            "--no-acl",
                            "--role=forgejo",
                            "--dbname=forgejo",
                        ),
                        stdin=source,
                    )
            state.rename(saved)
            try:
                staged.rename(state)
                replaced_state = True
            except BaseException:
                saved.rename(state)
                raise
            # Retained state must no longer be accessible to application users.
            saved.chmod(0o700)
            os.chown(saved, 0, 0)
        except BaseException:
            if replaced_state:
                failed = state.with_name(state.name + ".failed-restore-" + suffix)
                state.rename(failed)
                os.chown(saved, account.pw_uid, account.pw_gid)
                saved.chmod(0o700 if service == "pki" else 0o750)
                saved.rename(state)
            if renamed_db:
                self.sql("DROP DATABASE IF EXISTS forgejo WITH (FORCE)")
                self.sql('ALTER DATABASE "' + old_database + '" RENAME TO forgejo')
            raise
        finally:
            if staged.exists():
                shutil.rmtree(staged)


def main():
    require(os.geteuid() == 0, "corp-service-maintenance must run as root")
    os.umask(0o077)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", required=True, help=argparse.SUPPRESS)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("pki-check", "pki-backup", "forgejo-doctor", "forgejo-backup"):
        commands.add_parser(name)
    for name in ("pki-restore", "forgejo-restore"):
        command = commands.add_parser(
            name,
            help="Restore requires root-private approval JSON bound to encrypted backup SHA256",
        )
        command.add_argument("--backup", required=True)
        command.add_argument("--approve", required=True)
    args = parser.parse_args()
    cfg = json.loads(Path(args.config).read_text())
    service, action = args.command.split("-", 1)
    require(cfg[service]["enable"], "Requested service is not enabled")
    directory = private_directory("/run/corp-service-maintenance")
    lock = os.open(directory / "lock", os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        executor = Executor(cfg)
        with tempfile.TemporaryDirectory(
            prefix=service + "-", dir=directory
        ) as temporary:
            work = Path(temporary)
            if action == "check":
                executor.pki_check()
            elif action == "doctor":
                executor.forgejo_doctor()
            elif action == "backup":
                executor.backup(service, work)
            elif action == "restore":
                executor.restore(service, args.backup, args.approve, work)
    finally:
        os.close(lock)


if __name__ == "__main__":
    try:
        main()
    except MaintenanceError as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
    except BlockingIOError:
        print(
            "Another corporate service maintenance action is running", file=sys.stderr
        )
        sys.exit(1)
    except Exception:
        print(
            "Maintenance failed; no secret diagnostics are emitted. Inspect service state before retrying.",
            file=sys.stderr,
        )
        sys.exit(1)
