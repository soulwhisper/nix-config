# Forgejo {#module-forgejo}

This repository supplies a local `services.forgejo` module. Enable it with
`services.forgejo.enable` and set `services.forgejo.domain`. The packaged official
Forgejo binary, private PostgreSQL 18 cluster and state paths are service constants.
Both daemons use the existing `appuser` account, UID/GID1001; this is not a security
boundary against other processes running as that user.

## Existing Gitea deployments {#module-forgejo-migration-gitea}

This module does not enable upstream Gitea-to-Forgejo migration options or
implicitly import an existing database.

### Data migration {#module-forgejo-migration-gitea-default}

Follow the version-specific Forgejo migration instructions and verify an isolated
restore before moving an existing deployment. PostgreSQL major upgrades require
an explicit logical or physical migration, not reuse of an older data directory.

### Service identity {#module-forgejo-migration-gitea-impersonate}

The local service always uses `appuser`; it does not impersonate a former Gitea
account. Migrate state ownership explicitly along with the application and database.
