# Forgejo code platform

`nix-dev` hosts the company code collaboration plane. The AI application and its
production data remain on `ai-server`; this configuration does not deploy or
migrate that application.

## Included

- Forgejo with SQLite, Git LFS, private repositories and disabled self-registration.
- Caddy HTTPS and Forgejo's built-in SSH server.
- One trusted `nix:host` Actions runner, with a generated persistent registration
  credential and one-job concurrency.
- Thirty-day Actions log/artifact retention and local runner caching.
- Persistent Forgejo file logs and token-protected metrics.
- Gatus HTTPS/SSH checks and Pushover alerts.
- A tested cold Restic backup module for an external REST/SFTP repository. The
  `nix-dev` instance remains disabled until real repository credentials are added.

PostgreSQL, Kubernetes, a local mail server and a separate artifact registry are
not required for the current small trusted team. Forgejo Packages and Actions
artifacts are available for release artifacts. Do not send private build outputs
to the public Cachix cache used by the GitHub workflow.

## Internal access

Set the internal name in `hosts/nix-dev/default.nix`:

```nix
modules.services.forgejo = {
  enable = true;
  domain = "git.example.internal";
  rootUrl = "https://git.example.internal/";
  runner.enable = true;
};
```

The name must resolve to `nix-dev` for company users and the runner. Caddy
terminates HTTPS on 443 and proxies to Forgejo on 127.0.0.1:9003. Git SSH uses
port 9004. Do not add a public DNS record or public NAT/port forwarding for an
internal-only deployment. If a private CA is used, install its root certificate
in the system, runner and user trust stores.

## Required secrets before activation

The following keys are referenced when Restic is enabled. `nix-dev` initially
keeps `modules.services.restic.enable = false` so the host configuration can be
built without inventing an external repository. Before production cutover, add
real values with `sops hosts/nix-dev/secrets.sops.yaml` and change that option to
`true`. Activation fails closed if Restic is enabled while its keys are absent.

| Key | Required content |
|---|---|
| `backup/restic/repository` | Bare REST or SFTP repository URL |
| `backup/restic/auth` | Backend environment variables |
| `backup/restic/encryption` | Bare, independently generated Restic password |
| `alerting/pushover/auth` | Existing `PUSHOVER_TOKEN` and `PUSHOVER_KEY` environment file |

REST example (placeholders are not deployment values):

```yaml
backup:
  restic:
    repository: rest:https://backup.example.internal:8000/forgejo/
    auth: |
      RESTIC_REST_USERNAME={rest-username}
      RESTIC_REST_PASSWORD={rest-password}
    encryption: {independently-generated-restic-password}
```

For SFTP, use a `sftp:user@host:/path` repository URL and configure a dedicated
backup key plus strict host-key checking through
`modules.services.restic.extraOptions`. Do not reuse an administrator's SSH key.
Restic's SFTP backend requires non-interactive authentication.

Keep the Restic encryption password and the SOPS age recovery key offline. The
age key is under `/home`, not in the Forgejo Restic backup.

## Storage

New installations allocate 200 GiB to `/var/lib`. Disko does not resize an
existing LV during `nixos-rebuild`. On an existing `nix-dev`, verify the VG/LV
names and free thin-pool capacity first, then grow online:

```shell
sudo lvresize -L 200G main/app
sudo xfs_growfs /var/lib
```

This operation only grows the filesystem; do not shrink it as a rollback step.
Actions logs and artifacts expire after 30 days. Runner caches and Nix build
outputs are disposable and are not included in the Forgejo backup.

## First administrator and company users

After Forgejo is healthy, create the first administrator. `--random-password`
avoids placing a password in the command line; record the generated password in
the company password vault and change it at first login.

```shell
sudo -u forgejo env \
  GITEA_WORK_DIR=/var/lib/forgejo \
  FORGEJO_WORK_DIR=/var/lib/forgejo \
  forgejo admin user create \
  --username admin \
  --email {admin-email} \
  --admin \
  --random-password
```

Then use the web UI to create the organization, named users and teams. Local
accounts are sufficient initially; an identity provider is not required. Review
2FA enrollment, repository visibility and access quarterly. Disable leavers and
expired contractor accounts, revoke their tokens/SSH keys and transfer ownership
before removal.

Self-registration and anonymous repository viewing are disabled. Repository
creation defaults to private. Configure the protected `main` branch to require a
non-author approval. The same-host runner example runs only after an approved
push to `main`, or through an explicit manual dispatch. Pre-merge PR checks require
an isolated runner because PR workflows can be modified before review.

No mail server is configured. Web notifications work without one. If email is
required, connect the company SMTP relay and pass its password through
`services.forgejo.secrets.mailer.PASSWD`; never place it in `settings` or the Nix
store.

## Actions runner

`forgejo-runner-registration.service` creates
`/var/lib/forgejo/runner_token` once, after Forgejo starts. The file is an
environment file consumed by `gitea-runner-main.service`; it is not a Nix store
or SOPS value. The Restic backup preserves it.

The runner exposes only the `nix` label and executes directly on the host with
capacity 1, CPU/memory/task limits and no Docker socket. Host execution has no
container isolation. Therefore:

- use it only for approved private repositories and reviewed trusted changes;
- do not enable it for public forks, unreviewed contractor code or arbitrary
  user-supplied workflows;
- do not put `ai-server` production credentials in repository or organization
  secrets;
- use a separate isolated runner and protected approval environment before
  automating production deployment.

Enable Actions in each migrated repository's settings. This repository's example
workflow is `.forgejo/workflows/nix-build.yaml`; it builds `nix-dev` without
using the public Cachix cache.

## GitHub migration and cutover

1. Back up GitHub and the `ai-server` production working copy. Record the running
   production revision, local commits, uncommitted changes and untracked files.
2. Reconcile the production delta with GitHub history. Never overwrite the only
   production copy with an older GitHub checkout.
3. Remove production data, model weights, environments, caches and real secrets
   from the import. Add `.gitignore` and `.env.example`. Rotate exposed secrets
   before migration; deleting a file does not revoke a credential.
4. Create a private destination repository, push all required branches/tags and
   LFS objects, then enable Actions. Preserve GitHub as read-only during the
   verification window.
5. Verify commit/tag counts, LFS hashes and a fresh clone. Compare the source
   tree against the reconciled `ai-server` baseline and run its tests.
6. Switch developer remotes and CI to Forgejo. Do not write to both hosts during
   cutover. Do not redeploy `ai-server` merely because the remote changed.

Issue, PR, release and wiki history requires a separate export/import decision;
pushing Git refs does not migrate that metadata.

## Backup and restore

Once enabled, the `03:00` Restic timer stops `gitea-runner-main.service` and
`forgejo.service`, backs up `/var/lib/forgejo`, checks the repository and starts
the units in reverse order. Expect a short code-platform outage during this cold
backup. Retention is 7 daily, 5 weekly and 6 monthly snapshots.

Run an immediate backup and inspect snapshots with:

```shell
sudo systemctl start restic-backups-remote.service
sudo restic-remote snapshots
```

The wrapper reads the same SOPS-provided repository and credentials as the
systemd service. Use `systemctl start`, not the wrapper, for a consistent manual
backup; the wrapper alone does not quiesce Forgejo.

To restore onto a replacement host:

1. Install the matching NixOS configuration and provision the same Restic and
   age secrets. Stop `gitea-runner-main.service` and `forgejo.service`.
2. Restore and verify ownership:

   ```shell
   sudo restic-remote restore latest --target /
   sudo chown -R forgejo:forgejo /var/lib/forgejo
   sudo systemctl start forgejo.service
   sudo systemctl start gitea-runner-main.service
   ```

3. Verify login, private-repository authorization, HTTPS/SSH clone, LFS pull and
   an Actions job before changing DNS. Runner workspaces/caches are disposable;
   the preserved registration credential allows registration state to be rebuilt.
4. Keep the previous GitHub/Forgejo copy read-only until application and CI checks
   pass. A successful Restic snapshot is not evidence of recoverability without
   this exercise.

## Monitoring and logs

- Gatus listens on 9400 and checks Forgejo HTTPS and SSH. Backup and Runner unit
  failures still require alerts from the external Prometheus installation.
- Node exporter is on 9101. Forgejo metrics require
  `Authorization: Bearer` with `/var/lib/forgejo/metrics_token`; do not publish
  this token in scrape configuration or documentation.
- Forgejo file logs are under `/var/lib/forgejo/log`; Actions job logs and
  artifacts are stored by Forgejo. Use `journalctl -u forgejo -u
  gitea-runner-main` for current-boot unit diagnostics.

## Upgrade and rollback

Build and review the closure before switching on `nix-dev`:

```shell
just nixos build nix-dev
nvd diff /run/current-system result
just nixos switch nix-dev
```

Take a manual cold backup before Forgejo upgrades. Roll back the NixOS generation
with `sudo nixos-rebuild switch --rollback` if the new configuration fails. Do
not roll back only the binaries after a database migration without first
checking Forgejo's migration compatibility and restoring the matching backup.

## Verification

```shell
nix build .#ciSystems.nix-dev
nix build .#checks.x86_64-linux.forgejo
```

The VM check covers disabled registration, private repositories, administrator
creation, SSH clone, LFS, a real host-runner workflow, metrics, cold Restic
backup and an actual restore.
