{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.kms;
in
{
  options.modules.services.kms = {
    enable = lib.mkEnableOption "kms";
  };

  config = lib.mkIf cfg.enable {
    services.pykms = {
      enable = true;
      port = 1688;
      openFirewallPort = true;
    };
  };
}
