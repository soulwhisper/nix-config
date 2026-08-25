{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # ref:https://github.com/ryan4yin/nix-config/blob/main/modules/nixos/desktop/fhs.nix

    # FHS environment: run non-NixOS packages (AppImage, vendored binaries).
    # Invoked via the `fhs` command.
    environment.systemPackages = [
      (
        let
          base = pkgs.appimageTools.defaultFhsEnvArgs;
        in
        pkgs.buildFHSEnv (
          base
          // {
            name = "fhs";
            targetPkgs = pkgs: (base.targetPkgs pkgs) ++ [ pkgs.pkg-config ];
            profile = "export FHS=1";
            runScript = "bash";
            extraOutputsToInstall = [ "dev" ];
          }
        )
      )
    ];

    # nix-ld is enabled in hosts/_modules/nixos/default.nix; add the common
    # dynamic-linker libraries for proprietary binaries.
    programs.nix-ld.libraries = with pkgs; [
      stdenv.cc.cc
    ];
  };
}
