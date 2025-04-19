{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.shell.git;
  inherit (pkgs.stdenv) isDarwin;
in {
  options.modules.shell.git = {
    enable = lib.mkEnableOption "git";
    username = lib.mkOption {
      type = lib.types.str;
    };
    email = lib.mkOption {
      type = lib.types.str;
    };
    signingKey = lib.mkOption {
      type = lib.types.str;
    };
    config = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };
    includes = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      programs.gh.enable = true;
      programs.gpg.enable = true;

      programs.git = {
        enable = true;

        userName = cfg.username;
        userEmail = cfg.email;

        extraConfig = lib.mkMerge [
          {
            core = {
              autocrlf = "input";
            };
            init = {
              defaultBranch = "main";
            };
            pull = {
              rebase = true;
            };
            rebase = {
              autoStash = true;
            };
          }
          cfg.config
        ];

        includes = cfg.includes;

        aliases = {
          co = "checkout";
        };
        ignores = [
          # Temp
          "result/"
          # Mac OS X hidden files
          ".DS_Store"
          # Windows files
          "Thumbs.db"
          # Sops
          ".decrypted~*"
          # Devenv
          ".devenv*"
          "devenv.local.nix"
          "devenv.lock"
          # Others
          ".direnv"
          ".env"
          ".envrc"
          ".pre-commit-config.yaml"
        ];
        signing = {
          signByDefault = true;
          key = cfg.signingKey;
        };
      };

    #  home.packages = [
    #    pkgs.git-filter-repo
    #    pkgs.tig
    #  ];
    })
    (lib.mkIf (cfg.enable && isDarwin) {
      programs.git = {
        extraConfig = {
          credential = {helper = "osxkeychain";};
        };
      };
    })
  ];
}
