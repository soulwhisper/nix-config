{
  config,
  pkgs,
  ...
}: {
  config = {
    sops = {
      defaultSopsFile = ./secrets.sops.yaml;
      secrets = {
        # placeholder
      };
    };
  };
}
