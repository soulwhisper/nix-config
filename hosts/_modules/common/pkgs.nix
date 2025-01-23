{
  lib,
  pkgs,
  config,
  ...
}: {
  config = {
    # This will enable devenv and uv at all hosts
    environment.systemPackages = [
      pkgs.bashInteractive
      pkgs.devenv
      pkgs.direnv
      pkgs.unstable.uv
    ];
  };
}
