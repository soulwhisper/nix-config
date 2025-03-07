{
  config,
  pkgs,
  ...
}: {
  config = {
    sops = {
      defaultSopsFile = ./secrets.sops.yaml;
      secrets = {
        "apps/lobechat/auth" = {
          restartUnits = ["minio.service" "podman-lobechat.service"];
        };
      };
    };
  };
}
