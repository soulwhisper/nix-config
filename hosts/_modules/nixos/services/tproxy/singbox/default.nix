{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.tproxy;
in {
  config = lib.mkIf cfg.enable {
    # ! not finished yet !
  };
}
