{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.sftpgo;
in {
  options.modules.services.sftpgo = {
    enable = lib.mkEnableOption "sftpgo";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [2022 9202];

    # sftpgo could provide sftp, http/s, ftp/s, webdav sharing services;
    # backend using local filesystem, not encrypted;
    # ftp/webdav is disabled here;

    systemd.tmpfiles.rules = [
      "d /var/lib/shared 0755 appuser appuser - -"
    ];

    services.sftpgo = {
      enable = true;
      user = "appuser";
      group = "appuser";
      dataDir = "/var/lib/sftpgo";
      extraReadWriteDirs = [
        "/var/lib/shared"
      ];
      settings = {
        ftpd.bindings = [
          {
            address = "";
            port = 0;
          }
        ];
        sftpd.bindings = [
          {
            address = "";
            port = 2022;
          }
        ];
        httpd.bindings = [
          {
            address = "";
            port = 9202;
          }
        ]; # webui
        webdavd.bindings = [
          {
            address = "";
            port = 0;
          }
        ];
      };
    };
  };
}
