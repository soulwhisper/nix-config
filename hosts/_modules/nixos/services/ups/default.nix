{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.ups;
in
{
  options.modules.services.ups = {
    enable = lib.mkEnableOption "ups";
    mode = lib.mkOption {
        default = "netserver";
        type = lib.types.enum [ "none" "standalone" "netserver" "netclient" ];
    };
  };

  # santak-box summary needs to be corrected if at different usb port, with "nut-scanner -U"
  config = {
    networking.firewall.allowedTCPPorts = [ 3493 ];

    environment.etc = {
      "ups/password".source = pkgs.writeText "password" "pa55w0rd";
    };

    power.ups = {
      enable = true;
      inherit (cfg) mode;
      upsd.listen = [
        {
          address = "0.0.0.0";
          port = 3493;
        }
        {
          address = "::";
          port = 3493;
        }
      ];
      users.upsadmin.upsmon = "primary";
      users.upsadmin.actions = [ "SET" "FSD" ];
      users.upsadmin.instcmds = [ "ALL" ];
      users.upsadmin.passwordFile = "/etc/ups/password";
      users.upsuser.upsmon = "secondary";
      users.upsuser.passwordFile = "/etc/ups/password";
      ups.santak-box.summary =''
        pollinterval = 15
        maxretry = 3
        offdelay = 120
        ondelay = 240
      '';
      ups.santak-box.driver = "usbhid-ups";
      ups.santak-box.port = "auto";
      ups.santak-box.directives = [
        "vendorid=0463"
        "productid=SANTAK TG-BOX"
        "serial=Blank"
        "vendor=EATON"
        "bus=003"
      ];
      upsmon.monitor.santak-box.user = "upsadmin";
      upsmon.monitor.santak-box.type = "primary";
    };
  };
}
