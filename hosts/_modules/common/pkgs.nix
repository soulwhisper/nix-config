{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    # This will enable python3 and uv at all hosts
    environment.systemPackages = with pkgs; [
      bashInteractive
      git
      python3
      unstable.uv
    ];
  };
}
