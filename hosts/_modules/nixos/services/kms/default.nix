{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.kms;
in {
  options.modules.services.kms = {
    enable = lib.mkEnableOption "kms";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [1688];

    # python programs use libDir as HOME, pykms data is irrelevant

    services.pykms = {
      enable = true;
      port = 1688;
    };
  };
}
