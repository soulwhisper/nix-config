{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.users;
in
{
  options.modules.users = {
    appuser.enable = lib.mkEnableOption "appuser";
  };

  config = {
    users.mutableUsers = false;

    # appuser, 1001:1001
    users.users = lib.mkIf cfg.appuser.enable {
      appuser = {
        group = "appuser";
        uid = 1001;
        isSystemUser = true;
      };
    };
    users.groups = lib.mkIf cfg.appuser.enable {
        appuser.gid = 1001;
    };

    systemd.tmpfiles.rules = lib.mkIf cfg.appuser.enable [
      "d /opt/apps 0644 appuser appuser - -"
    ];
  };
}
