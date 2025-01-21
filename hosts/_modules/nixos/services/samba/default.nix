{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.samba;
in {
  options.modules.services.samba = {
    enable = lib.mkEnableOption "samba";
    avahi.TimeMachine.enable = lib.mkEnableOption "avahi-timemachine";
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.samba-users = {};

    networking.firewall.allowedTCPPorts = [445];
    networking.firewall.allowedUDPPorts = [5353];

    services.samba = {
      enable = true;
      package = pkgs.samba;

      settings =
        {
          global = {
            "workgroup" = "HOMELAB";
            "min protocol" = "SMB2";

            "ea support" = "yes";
            "vfs objects" = "acl_xattr, catia, fruit, streams_xattr";
            "fruit:metadata" = "stream";
            "fruit:model" = "MacSamba";
            "fruit:veto_appledouble" = "no";
            "fruit:posix_rename" = "yes";
            "fruit:zero_file_id" = "yes";
            "fruit:wipe_intentionally_left_blank_rfork" = "yes";
            "fruit:delete_empty_adfiles" = "yes";
            "fruit:nfs_aces" = "no";

            "browsable" = "yes";
            "guest only" = "no";
            "map to guest" = "never";
            "inherit acls" = "yes";
            "map acl inherit" = "yes";
            "valid users" = "@samba-users";

            "veto files" = "/._*/.DS_Store/";
            "delete veto files" = "yes";
          };
        }
        // cfg.settings;
    };

    # enable avahi service for volume:TimeMachine
    services.avahi = lib.mkIf cfg.avahi.TimeMachine.enable {
      enable = true;
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
              <txt-record>model=TimeCapsule8,119</txt-record>
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
