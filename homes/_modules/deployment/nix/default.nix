{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.deployment.nix;
in {
  options.modules.deployment.nix = {
    enable = lib.mkEnableOption "nix-deployment";
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [
        pkgs.nvd
      ]
      ++ (lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.nixos-rebuild);
  };
}
