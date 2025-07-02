{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    # This will enable mise and uv at all hosts
    environment.systemPackages = [
      pkgs.bashInteractive
      pkgs.git
      pkgs.python3
      pkgs.mise
      pkgs.unstable.uv
    ];
  };
}
