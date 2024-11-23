{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.nix-cache;
in
{
  options.modules.services.nix-cache = {
    enable = lib.mkEnableOption "nix-cache";
  };

  config = lib.mkIf cfg.enable {
    environment.etc = {
        "nix-cache/upload-cache.sh".source = pkgs.writeTextFile {
        name = "post-build-hook";
        text = builtins.readFile ./upload-cache.sh;
        };
    };

    # nix-store --generate-binary-cache-key s3.noirprime.com nix-cache-key.private nix-cache-key.public
    environment.etc = {
        "nix-cache/nix-cache-key.private".source = pkgs.writeTextFile {
        name = "nix-cache-key.private";
        text = builtins.readFile ./nix-cache-key.private;
        };
    };
  };
}
