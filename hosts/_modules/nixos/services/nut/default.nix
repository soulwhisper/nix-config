{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.nut;
in {
  options.modules.services.nut = {
    enable = lib.mkEnableOption "nut";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [3493];

    environment.etc = {
      "nut/password".source = pkgs.writeText "password" "sEcr3T!";
    };

    powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

    power.ups = {
      enable = true;
      mode = "netserver";
      ups."santak-box" = {
        driver = "usbhid-ups";
        port = "auto";
        description = "SANTAK TG-BOX 850";
        directives = ["default.battery.charge.low = 75"];
      };
      users."upsmon" = {
        upsmon = "primary";
        actions = ["SET" "FSD"];
        instcmds = ["ALL"];
        passwordFile = "/etc/nut/password";
      };
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
      upsmon.monitor."santak-box".user = "upsmon";
    };
  };
}
