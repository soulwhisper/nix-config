{
  config,
  lib,
  ...
}:
{
  config = {
    users = {
      mutableUsers = false;

      # appuser, 1001:1001
      users = {
        appuser = {
          group = "appuser";
          uid = 1001;
          isSystemUser = true;
        };
      };
      groups = {
        appuser.gid = 1001;
      };
    };

    systemd.tmpfiles.rules = [
      "d /opt/apps 0644 appuser appuser - -"
      "d /opt/logs 0644 appuser appuser - -"
    ];
  };
}
