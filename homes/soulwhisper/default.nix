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
      "nix-nas.homelab.internal" = {
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
        enable = true;
        # use official sync server for now
        # sync_address = "https://atuin.homelab.internal";
        key_path = config.sops.secrets.atuin_key.path;
      };
      git = {
        enable = true;
        username = "Hekatos Noir";
        email = "soulwhisper@outlook.com";
        signingKey = "DF405879732AE5F2";
      };
    };
  };
}
