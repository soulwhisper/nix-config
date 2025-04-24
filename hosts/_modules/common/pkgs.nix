{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    # This will enable devenv and uv at all hosts
    environment.systemPackages = [
      pkgs.bashInteractive
      pkgs.devenv
      pkgs.git
      pkgs.python3
      pkgs.unstable.uv
    ];
  };
}
