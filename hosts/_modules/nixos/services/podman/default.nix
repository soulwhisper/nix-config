{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.services.podman;
in
{
  options.modules.services.podman = {
    enable = lib.mkEnableOption "podman";
    package = lib.mkPackageOption pkgs "docker-compose" { };
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        autoPrune.enable = true;
      };
      oci-containers.backend = "podman";
    };
  };
}
