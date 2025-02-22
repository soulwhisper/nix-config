{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.modules.services.podman;
in {
  options.modules.services.podman = {
    enable = lib.mkEnableOption "podman";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      podman-compose
      docker-compose
    ];

    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        autoPrune.enable = true;
      };
      oci-containers.backend = "podman";
    };
    virtualisation.oci-containers.containers."watchtower" = {
      autoStart = true;
      image = "containrrr/watchtower";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "/etc/localtime:/etc/localtime:ro"
      ];
    };
  };
}
