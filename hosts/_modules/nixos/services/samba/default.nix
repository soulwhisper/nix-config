{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.timemachine;
in {
  options.modules.services.timemachine = {
    enable = lib.mkEnableOption "timemachine";
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/shared/timemachine";
    };
    maxSize = lib.mkOption {
      type = lib.types.str;
      default = "200G";
    };
  };

  config = lib.mkIf cfg.enable {
    # this module for MacOS TimeMachine only;
    # http://gwiki.samba.org/index.php/Configure_Samba_to_Work_Better_with_Mac_OS_X

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0700 root root - -"
    ];

    users.groups.samba-users = {};

    networking.firewall.allowedTCPPorts = [445];
    networking.firewall.allowedUDPPorts = [5353];
    networking.firewall.allowedUDPPortRanges = [
      {
        from = 32768;
        to = 65535;
      }
    ]; # add random high ports for avahi

    services.samba = {
      enable = true;
      nmbd.enable = false;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "valid users" = "@samba-users";
          "writeable" = "yes";

          "vfs objects" = "fruit, streams_xattr";
          # defaults in vfs_fruit, https://www.samba.org/samba/docs/current/man-html/vfs_fruit.8.html
          # "fruit:model" = "MacSamba";
          # "fruit:posix_rename" = "yes";
          "fruit:metadata" = "stream";
          "fruit:veto_appledouble" = "no";
          "fruit:wipe_intentionally_left_blank_rfork" = "yes";
          "fruit:delete_empty_adfiles" = "yes";
          "fruit:nfs_aces" = "no";

          "veto files" = "/._*/.DS_Store/";
          "delete veto files" = "yes";
        };
        TimeMachine = {
          path = "${cfg.dataDir}";
          "fruit:time machine" = "yes";
          "fruit:time machine max size" = "${cfg.maxSize}";
        };
      };
    };

    services.avahi = {
      enable = true;
      publish = {
        enable = true;
        userServices = true;
      };
      extraServiceFiles = {
        smb = ''
          <?xml version="1.0" standalone='no'?>
          <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
          <service-group>
            <name replace-wildcards="yes">%h</name>
            <service>
              <type>_smb._tcp</type>
              <port>445</port>
            </service>
            <service>
              <type>_device-info._tcp</type>
              <port>0</port>
              <txt-record>model=RackMac</txt-record>
            </service>
            <service>
              <type>_adisk._tcp</type>
              <txt-record>dk0=adVN=TimeMachine,adVF=0x82</txt-record>
              <txt-record>sys=waMa=0,adVF=0x100</txt-record>
            </service>
          </service-group>
        '';
      };
    };
  };
}
