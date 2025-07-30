{
  config,
  hostname,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../_modules
    ./secrets
    ./hosts/${hostname}.nix
  ];

  modules = {
    security.ssh.matchBlocks = {
      "nix-dev.homelab.internal" = {
        port = 22;
        user = "soulwhisper";
        forwardAgent = true;
      };
      "nix-ops.homelab.internal" = {
        port = 22;
        user = "soulwhisper";
        forwardAgent = true;
      };
      "nix-infra.homelab.internal" = {
        port = 22;
        user = "soulwhisper";
        forwardAgent = true;
      };
    };

    shell = {
      atuin = {
        # use official sync server for now
        # sync_address = "https://atuin.homelab.internal";
        key_path = config.sops.secrets.atuin_key.path;
      };
    };
  };
}
