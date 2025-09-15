## Archived Services

- Deprecated due to k8s migration;

### Usage

> hosts

```shell
  crafty.enable = true; # sub=mc
  emby.enable = true; # sub=movie
  freshrss.enable = true; # sub=rss
  freshrss.authFile = config.sops.secrets."apps/default/auth".path;
  fvtt.enable = true; # sub=fvtt
  fvtt.authFile = config.sops.secrets."apps/fvtt/auth".path;
  immich.enable = true; # sub=photo
  karakeep.enable = true; # sub=bookmarks
  moviepilot.enable = true; # sub=pilot
  moviepilot.authFile = config.sops.secrets."apps/moviepilot/auth".path;
  n8n.enable = true; # sub=n8n
  qbittorrent.enable = true; # sub=bt
  sillytavern.enable = true; # sub=tavern
```

> secrets

```
  sops.secrets = {
    "apps/fvtt/auth" = {
      owner = config.users.users.soulwhisper.name; # node uid=1000
      restartUnits = ["podman-fvtt.service"];
    };
    "apps/moviepilot/auth" = {
      owner = config.users.users.appuser.name;
      restartUnits = ["podman-moviepilot.service"];
    };
  }
```
