{
  config,
  lib,
  ...
}: {
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

    # recursive permissions is needed for some apps, i.e. adguardhome
    systemd.tmpfiles.rules = [
      "d /opt 0700 appuser appuser - -"
      "d /opt/apps 0700 appuser appuser - -"
      "d /opt/logs 0700 appuser appuser - -"
    ];
  };
}
