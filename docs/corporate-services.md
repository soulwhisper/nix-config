# Corporate PKI and Forgejo

## Activation prerequisite

The `nix-dev` configuration enables the services, but production issuer material
is deliberately not generated or represented by dummy values. Before activating
this configuration, provision all four `pki/*` SOPS values below. Until then this
change is suitable for a draft review, **not a production switch**: secret
installation or service startup must fail rather than create another authority.
Missing regular SOPS secrets can also prevent other regular secrets from being
installed; do not assume the failure is limited to the PKI unit.

Do not paste private keys, passwords, or decrypted SOPS documents into a PR,
terminal transcript, or chat. Provision through the controller tool or the SOPS
editor, and commit only encrypted output. Preserve the existing root identity if
one has already been approved; importing it must not silently create a new root.

## Ownership and runtime boundaries

| Component | Responsibility |
|---|---|
| Root authority environment | Encrypted root key, issuer approvals, CA index/serial/CRL state, root backups and rollover |
| Controller | Intermediate key/CSR preparation, material validation, atomic encrypted SOPS staging, revision approval and deployment |
| Linux controller or CI | Build the exact NixOS system closure; no CA decryption is needed |
| `nix-dev` | Decrypt approved runtime secrets, validate them, run services and execute approved maintenance |

`nix-dev` is not a controller or an offline root. The online intermediate key is
necessarily available to step-ca. The online daemons use the repository's shared
`appuser` (UID/GID1001): this avoids running them as root, but does not isolate
services from a hostile process with the same UID. Root or appuser compromise can
therefore compromise the intermediate. The root key and its decryption identity
must stay off this host, including outside the blanket repository age recipient
rule. Root state stays outside the repository and outside `/nix/store`.

The services are native NixOS/systemd services, not the archive's Docker stacks:

- `services.pki` defines local systemd units using `pkgs.unstable.step-ca` and a
  persistent Badger database; it does not adapt upstream `services.step-ca`.
- `services.forgejo` is a minimal local module, not the upstream service option
  tree. `pkgs.corp-forgejo` wraps the official Forgejo binary with service paths
  and dependencies; configure the hostname with `services.forgejo.domain`.
- Forgejo uses its own PostgreSQL 18 cluster and restricted application role.
- All Caddy instances retain `pkgs.caddy-custom`. The Cloudflare provider is a
  configuration choice, not a different package variant.

## Network and trust

| Endpoint | Contract |
|---|---|
| `https://git.internal.htkrail.com/` | Forgejo web and HTTPS Git |
| `https://pki.internal.htkrail.com/root_ca.crt` | Public root certificate |
| `https://localhost:9700/acme/acme/directory` | Local-only ACME directory |
| `127.0.0.1:9003` | Forgejo HTTP backend; never an external listener |
| `/run/postgresql-forgejo` | Dedicated PostgreSQL Unix socket; no TCP listener |

Both public names must resolve internally to `nix-dev`, including from step-ca
itself. TLS-ALPN-01 validation connects back to Caddy on TCP443. The CA HTTPS
bootstrap certificate includes `localhost`; changing its URL requires a
corresponding SAN. No remote ACME access or port9700 firewall opening is needed.
Git SSH is disabled; administrative SSH remains separate.

Authenticate the root certificate's SHA-256 certificate fingerprint through an
independent channel before installing trust. A PEM file checksum is not that
fingerprint. Neither downloading a root over an initially untrusted HTTPS
connection nor Caddy's trust of the ACME server installs trust on user browsers,
CI runners, Java applications, or containers.

Caddy serves public artifacts from `/run/pki-public`, never from the CA database
or SOPS directory. `tls internal` is not used for these corporate sites.

## SOPS issuer set

`hosts/nix-dev/secrets.nix` declares the runtime interface. Supply these values in
`hosts/nix-dev/secrets.sops.yaml`, under the nested `pki` object:

| Key | Content and runtime access |
|---|---|
| `pki/root-ca-crt` | Approved public root PEM; readable by Caddy and step-ca |
| `pki/intermediate-crt` | Root-signed intermediate PEM; public |
| `pki/intermediate-key` | Matching encrypted intermediate private-key PEM; owned by appuser, passed to step-ca as a credential |
| `pki/intermediate-password` | Bare unlock password; systemd passes it through `LoadCredential` |

All four service file options use `lib.types.path`. The host supplies
`config.sops.secrets.<name>.path` strings. Modules never read those files during
Nix evaluation or build, and private material must not be supplied as a Nix path
literal such as `./private.key`.

Treat the intermediate certificate, private key and password as one issuer set:
validate the chain, CA constraints, validity and key match before committing;
deploy them together at one reviewed revision. Startup validation repeats the
checks and fails closed. SOPS generation publication is not an end-to-end
service transaction or automatic health rollback.

Issuer changes restart step-ca so that its copied password credential is
refreshed. Ordinary intermediate rotation does not require replacing the root
or stopping Forgejo. Existing Caddy certificates remain usable until their own
expiry. ACME leaf certificates and account/database state are not fixed in SOPS.

## Controller installation

Enable the independently importable Home Manager feature on a controller:

```nix
modules.deployment.enable = true;
```

It registers fish functions `rca`, `pki`, `deploy`, and `fjo`, backed by the same
CLI implementations used outside fish. The repository overlay supplies
`pkgs.corp-root-ca` and `pkgs.corp-deployment-tools`; the Home module references
those packages directly, without `callPackage` or another packaging path.
It does not require development, mise, Kubernetes, NixOS service options, or
Home Manager's SOPS module. Enabling it does not unlock keys, generate a CA,
or deploy a system. The feature is off by default; `nix-dev` has no explicit
enable/disable override.

Each function references its packaged executable's store path. When this feature
is enabled, the normal Home Manager or host build recursively builds the tools
and their dependencies; no separate CI package-build step is needed. Overlay
registration alone does not add an otherwise unused package to a system closure.

The tool packages are also available directly:

```shell
nix run .#corp-root-ca -- --help
nix run .#corp-deployment-tools -- --help
```

Linux controllers can build locally. Darwin controllers need an explicitly
selected Linux builder or a prebuilt Linux closure. Do not silently use
`nix-dev` as a build machine. The existing Ubuntu/Cachix CI can provide builds;
match a concrete source revision and system store path, not a cache's notion of
"latest".

## First provisioning and issuer rotation

1. Create or import the root authority in its protected root environment. A
   certificate-only import cannot sign. If historical issuance state is missing,
   acknowledge incomplete history explicitly rather than inventing it.
2. On the controller, create an encrypted intermediate key, password and CSR in
   an explicitly chosen private directory. Transfer only the CSR to the root
   environment.
3. Review the complete CSR, root fingerprint, requested validity and approved
   issuer-controlled profile. Sign a pathlen-zero intermediate; do not copy
   arbitrary CSR extensions or allow its validity to exceed the root's.
4. Return only the public root and signed intermediate certificate. Validate the
   independently authenticated root fingerprint and match the new certificate
   to the controller's private key.
5. Stage the complete issuer set into SOPS. Preserve unrelated secret values and
   recipients; do not rekey or weaken the rest of the document. Never commit a
   plaintext staging document.
6. Review the encrypted change and pinned deployment revision, build and diff the
   system, then explicitly approve activation from the controller.
7. Verify CA health, a fresh ACME issuance, normal DNS resolution and both HTTPS
   endpoints. Keep secured rollback material while the change window remains
   open; old public chains and old private keys have different retention needs.

For routine intermediate rotation, use a new key and CSR under the same root.
Do not auto-revoke the old intermediate while its legitimately issued leaves
are still in use. Schedule the ceremony well before intermediate expiry.

The root tool maintains the OpenSSL CA database, issued certificates, approvals,
serial and CRL state under an exclusive mutation lock. It supports initial
creation/import, intermediate signing/rotation/revocation, CRL refresh,
encrypted whole-state backup/restore, root rollover and retirement. An unknown
historical serial is not evidence that a certificate was never revoked.

### Root ceremony and controller commands

These examples use shell variables for operator-supplied paths, authenticated
fingerprints, age recipients and change references. Keep private directories and
password files outside the checkout. Passphrases are private files or inherited
seekable file descriptors, never command-line values.

On the root authority machine, choose **one** initial operation. `init` is only
for an explicitly approved new root; `import` preserves an existing identity:

```shell
root-ca --state "$ROOT_STATE" init --subject "$ROOT_SUBJECT" \
  --days 3650 --passphrase-file "$ROOT_PASSPHRASE_FILE"

root-ca --state "$ROOT_STATE" import --certificate "$EXISTING_ROOT_CERT" \
  --key "$EXISTING_ENCRYPTED_ROOT_KEY" --history-directory "$OPENSSL_CA_HISTORY" \
  --passphrase-file "$ROOT_PASSPHRASE_FILE"

root-ca --state "$ROOT_STATE" status
root-ca --state "$ROOT_STATE" fingerprint
root-ca --state "$ROOT_STATE" export --output "$NEW_PUBLIC_DIRECTORY"
```

The import history directory contains `index.txt`, `serial`, `crlnumber` and
`newcerts/`, plus `root.crl` when available. Missing history requires the explicit
`--acknowledge-incomplete-history` alternative, not an empty invented history.
Export destinations must be new; the root key is never exported.

On the controller:

```shell
pki-admin generate --directory "$NEW_ISSUER_DIRECTORY" \
  --common-name "$INTERMEDIATE_COMMON_NAME" --recipient "$CONTROLLER_AGE_RECIPIENT"
```

Transfer `intermediate.csr` to the root machine. Review the plan before supplying
its `approval` digest to the signing command with identical inputs:

```shell
root-ca --state "$ROOT_STATE" intermediate plan --csr "$CSR" \
  --days 365 --change "$CHANGE_REFERENCE"
root-ca --state "$ROOT_STATE" intermediate sign --csr "$CSR" \
  --days 365 --change "$CHANGE_REFERENCE" --approval "$REVIEWED_APPROVAL" \
  --output "$NEW_INTERMEDIATE_CERT" --passphrase-file "$ROOT_PASSPHRASE_FILE"
```

For a replacement, add `--replaces "$OLD_INTERMEDIATE_SERIAL"` to the plan and use
`intermediate rotate` with that same argument instead of `intermediate sign`.
Changing a CSR, validity, change reference, selected root or state generation
invalidates the approval. If publication fails after a committed issuance, recover
the existing certificate with `export --serial "$SERIAL" --output "$NEW_DIRECTORY"`;
do not issue another certificate just to recover a lost output file.

Return the public root and signed certificate to the controller:

```shell
pki-admin validate --directory "$NEW_ISSUER_DIRECTORY" \
  --certificate "$NEW_INTERMEDIATE_CERT" --root "$PUBLIC_ROOT_CERT" \
  --root-fingerprint "$AUTHENTICATED_ROOT_FINGERPRINT" \
  --identity "$CONTROLLER_AGE_IDENTITY"

pki-admin stage --directory "$NEW_ISSUER_DIRECTORY" \
  --certificate "$NEW_INTERMEDIATE_CERT" --root "$PUBLIC_ROOT_CERT" \
  --root-fingerprint "$AUTHENTICATED_ROOT_FINGERPRINT" \
  --identity "$CONTROLLER_AGE_IDENTITY" \
  --sops-file hosts/nix-dev/secrets.sops.yaml
```

`--identity` unlocks the controller's age-encrypted intermediate password. SOPS
separately uses its normal configured identities, for example
`SOPS_AGE_KEY_FILE`, to preserve and update the existing encrypted document.
Only new SOPS files accept explicit `--recipient` values. Existing recipients,
unrelated secrets and encryption-suffix protections must remain unchanged.


## Deployment and rollback

Use the controller's deployment CLI or the corresponding `just nixos` recipe.
The source revision, target and resulting system store path are explicit.
Deployment copies a built closure to the target, shows the closure diff and
requires approval before setting the system profile or activating it. SSH host
key verification is not disabled. No real activation is performed by package
checks or by enabling the Home Manager module.

Use a clean checkout at the exact committed revision, including no untracked
files. Keep plan files outside it. A typical Linux controller sequence is:

```shell
REVISION=$(git rev-parse HEAD)
SYSTEM=$(deploymentctl build --repo "$CHECKOUT" --host nix-dev --revision "$REVISION")
deploymentctl plan --repo "$CHECKOUT" --host nix-dev --target "$SSH_TARGET" \
  --revision "$REVISION" --system "$SYSTEM" --out "$NEW_PLAN"
deploymentctl diff --plan "$NEW_PLAN"
deploymentctl deploy --plan "$NEW_PLAN" --approve "$REVIEWED_DEPLOY_APPROVAL"
deploymentctl status --target "$SSH_TARGET"
```

The plan prints distinct `deploy:` and `rollback:` approval values. Inspect its
revision, closure and previous system before using either. `copy` and `activate`
can split transfer from activation; `deploy` performs both. On Darwin, pass an
explicit Linux `--builder ssh://user@builder` to `build`, or use the exact
CI-built closure in `plan --system`.

An activation failure restores the previous profile pointer but deliberately
does **not** reactivate an old issuer automatically. Inspect the running state
and authorize an explicit rollback only if it is safe:

```shell
deploymentctl rollback --plan "$NEW_PLAN" --approve "$REVIEWED_ROLLBACK_APPROVAL"
```


A NixOS generation rollback does not undo Forgejo schema migrations, repository
writes, ACME account state or revocations. Restore persistent data only through a
separately approved recovery operation. Do not roll back to an intermediate
whose key has been compromised, and do not restore an old CA database in a way
that forgets later revocations.

After material provisioning and controlled activation, inspect the actual units:

```shell
systemctl status step-ca.service caddy.service forgejo.service postgresql-forgejo.service
```

## Database isolation and upgrades

Forgejo, `postgresql-forgejo.service`, and step-ca all run as the existing
`appuser:appuser` (1001:1001); no service-specific OS users are created. The
private PG18 state is `/var/lib/postgresql-forgejo/18` and its socket directory
is `/run/postgresql-forgejo`, both restricted to appuser and root.

The HBA policy maps appuser to the non-superuser SQL role `forgejo` only for the
`forgejo` database. The SQL administrator `forgejo-db-admin` maps **OS root only**;
root provisioning runs after PostgreSQL reports readiness. Other roles/databases
and replication are rejected. The cluster has `listen_addresses = ''`.

This separates PostgreSQL instances and prevents accidental use of the shared
cluster; it is not a boundary against another hostile appuser process, which
shares filesystem access and the application peer identity. Do not describe the
shared UID as per-service isolation. Different OS UIDs or another security
boundary would be required for that.

The global `services.postgresql` instance, its roles, data and socket are not
modified. All administration and dump commands use the pinned PG18 tools and an
explicit private socket. Initialization only accepts an empty directory; an
unrecognized nonempty directory or wrong `PG_VERSION` is an error, not a reason
to delete files or initialize another empty cluster.

For an existing PG16 deployment, prefer a logical dump/restore into the new
private PG18 cluster. Never point PG18 at PG16's data directory. Future physical
upgrades require old/new binaries, separate data, checksum/locale/extension
compatibility checks and a retained recovery copy; a package-version bump alone
is not a major-version migration.

## Backups and restore authorization

Host backup timers encrypt immediately to the configured public age recipient.
The root-authority environment uses independent offline backup recipients and
its own whole-state recovery procedure.

- PKI backup stops the Badger writer while capturing its state and the matching
  deployed issuer/configuration. Keep CA, account and revocation state together.
- Forgejo backup quiesces application writes, captures a PG18 logical dump plus
  repositories, LFS, attachments and application secrets, then restores service.
  Its generated INI, persistent secret files, repositories, and LFS remain under
  `/var/lib/forgejo`; the local bootstrap preserves secrets across restarts.
- Do not ordinary-copy live PostgreSQL data as a backup. If using the generic
  Restic `/var/lib` backup, exclude live PGDATA and include finished logical
  backups instead.
- Preserve Caddy's ACME/account and leaf-key state separately. Restoring the
  issuer is not a reason to overwrite unrelated Caddy state.
- Copy encrypted archives off-host and periodically restore into an isolated
  environment. Local encryption alone is not off-host disaster recovery.

Setting `services.<service>.backup.recipient` enables the fixed daily timer and
encrypted output under `/var/backup/corp/<service>`. Only the public recipient
and optional runtime `backup.identityFile` are configuration inputs; addresses,
ports, state paths, timer calendar and backup directories are service constants.
The host-service archive format is version2 for the local-unit/appuser layout;
older draft-format archives are rejected rather than silently restoring a
different secret/state contract. The separate offline Root CA archive format is
unchanged.

Restore requires explicit approval bound to the service, action and archive
SHA-256, plus a real root-owned age identity with restrictive permissions. The
configured identity path is `/run/corp-service-backup/identity.txt`; it is only
needed for restoration, not normal startup or encryption. A recovery operator
must supply it securely when needed and remove it afterward. Do not substitute a
root CA signing key or loosen the private-key ownership check.

The target maintenance executor validates archive paths, rejects unsafe members,
and keeps failed recovery distinguishable from a successful restart. Do not
bypass it by unpacking an archive over a running service. Failed restore leaves
the service stopped rather than automatically restarting against uncertain state.
Root-authority restore also requires an independently retained ciphertext SHA-256
and generation/CRL publication records. Age encryption alone does not authenticate
the backup sender: anyone who knows the public recipient can encrypt a file.

Service restoration reinstalls state as appuser (UID/GID1001) and retains the
pre-restore directory as root-private recovery state. Before accepting recovery,
run the PKI check and Forgejo doctor, then verify trusted HTTPS and a Git/LFS
round trip; a successful archive extraction alone is not recovery evidence.

On the root machine, retain the backup command's public JSON record separately
from the ciphertext. It includes the ciphertext digest, generation and root
fingerprints; the password file remains a separate recovery prerequisite:

```shell
root-ca --state "$ROOT_STATE" backup --recipient "$OFFLINE_BACKUP_RECIPIENT" \
  --output "$NEW_ENCRYPTED_BACKUP"
root-ca --state "$NEW_RECOVERY_STATE" restore --input "$ENCRYPTED_BACKUP" \
  --identity "$OFFLINE_BACKUP_IDENTITY" \
  --expected-sha256 "$TRUSTED_BACKUP_SHA256" \
  --minimum-generation "$TRUSTED_LATEST_GENERATION" \
  --expected-fingerprint "$AUTHENTICATED_ACTIVE_ROOT_FINGERPRINT"
root-ca --state "$NEW_RECOVERY_STATE" verify
```

When an existing same-lineage state survives, also pass `--reference-state` to
reject stale backups. Restore advances the generation high-water mark; never
resume both the original and recovered signing databases concurrently.

## Revocation and trust retirement

Authority allow/deny policy is declarative; do not edit generated `ca.json`.
The native step renewal/rekey route is disabled for this ACME-only deployment,
while Caddy continues renewal through new ACME orders. In step-ca0.30.2, a domain
policy alone does not constrain the native renewal path.

Do not reuse the archive's serial-only offline revoke helper with an ACME-only
provisioner. A leaf owner can use certificate-key-authorized RFC8555 revocation:

```shell
pki-admin revoke --target "$SSH_TARGET" --certificate "$LEAF_CERTIFICATE" \
  --private-key "$LEAF_PRIVATE_KEY" --root "$AUTHENTICATED_ROOT_CERT" --reason 1
```

Encrypted leaf keys additionally require `--key-password-file`. This command
signs locally and reaches only `localhost:9700` through verified SSH; it neither
copies the private key to the target nor opens an external CA listener. It
rejects CA certificates and mismatched keys. Contain the validation endpoint and
change issuance policy after compromise. Revocation is not a promise of immediate
browser rejection or removal of a still-cached leaf.

Revoke an old intermediate only after evaluating its remaining live leaves,
using the root machine and a separate approval:

```shell
root-ca --state "$ROOT_STATE" intermediate revoke --serial "$OLD_SERIAL" \
  --reason superseded --change "$CHANGE_REFERENCE" --crl-days 30 --plan
root-ca --state "$ROOT_STATE" intermediate revoke --serial "$OLD_SERIAL" \
  --reason superseded --change "$CHANGE_REFERENCE" --crl-days 30 \
  --approval "$REVIEWED_APPROVAL" --passphrase-file "$ROOT_PASSPHRASE_FILE"
root-ca --state "$ROOT_STATE" crl verify
root-ca --state "$ROOT_STATE" export --output "$NEW_PUBLIC_DIRECTORY"
```

Refresh publication before CRL expiry with `crl issue --days 30
--passphrase-file "$ROOT_PASSPHRASE_FILE"`. If CRL enforcement/publication is
required on the host, declare its own SOPS secret and set the path-typed
`services.pki.rootCRLFile` option; the four mandatory issuer secrets do not
implicitly install a CRL.

Root-issued CRLs revoke intermediates, not installed root trust or every leaf
underneath them. For root rollover, create a new authority within the protected
state lineage, distribute old and new authenticated trust first, switch
issuance/chains, then retire old trust according to actual certificate expiry
and client migration evidence:

```shell
root-ca --state "$ROOT_STATE" rollover --subject "$NEW_ROOT_SUBJECT" \
  --days 3650 --change "$CHANGE_REFERENCE" --plan
root-ca --state "$ROOT_STATE" rollover --subject "$NEW_ROOT_SUBJECT" \
  --days 3650 --change "$CHANGE_REFERENCE" --approval "$REVIEWED_APPROVAL" \
  --passphrase-file "$NEW_ROOT_PASSPHRASE_FILE"
root-ca --state "$ROOT_STATE" export --output "$NEW_OVERLAP_PUBLIC_DIRECTORY"

root-ca --state "$ROOT_STATE" --authority "$OLD_ROOT_FINGERPRINT" retire \
  --change "$RETIREMENT_CHANGE_REFERENCE" --plan
root-ca --state "$ROOT_STATE" --authority "$OLD_ROOT_FINGERPRINT" retire \
  --change "$RETIREMENT_CHANGE_REFERENCE" --approval "$REVIEWED_RETIREMENT_APPROVAL" \
  --acknowledge-external-trust-removal
```

The overlap export contains public roots under `roots/`; distribute them through
the client trust-management channel, not by adding a PEM bundle to the
single-certificate service option. Select `--authority "$OLD_ROOT_FINGERPRINT"`
for old-root CRL/revocation work during overlap. Retirement is a local state
transition and an explicit operator assertion about external trust removal; it
cannot erase remote trust stores, cached chains or historical backups.

## Acceptance evidence required before production

- Real ACME first issuance and update; reject disallowed names and native
  renewal; match normal DNS, hostname and trust, without `-k`.
- Git login, HTTPS clone/push and LFS; no externally reachable HTTP backend or
  database listener.
- Peer authentication with UID1001: allow only the Forgejo application role and
  database, reject appuser administrative login, and allow the root-only admin map.
- Cold start waits for completed DB provisioning; restart preserves data and
  wrong-major initialization fails safely.
- Full encrypted backup/restore of both services and root authority, including
  failure paths and stale-state handling.
- CA maintenance does not stop Forgejo or Caddy while their current leaf
  certificates remain valid.
