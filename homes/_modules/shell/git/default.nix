{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.shell.git;
in {
  options.modules.shell.git = {
    config = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };
    username = lib.mkOption {
      type = lib.types.str;
    };
    email = lib.mkOption {
      type = lib.types.str;
    };
    signingKey = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = {
    programs.gh.enable = true;
    programs.gh-dash.enable = true;
    programs.lazygit.enable = true;
    programs.git = {
      enable = true;
      delta.enable = true;
      userName = cfg.username;
      userEmail = cfg.email;
      signing = {
        signByDefault = true;
        key = cfg.signingKey;
      };
      extraConfig = lib.mkMerge [
        cfg.config
        {
          core.autocrlf = "input";
          init.defaultBranch = "main";
          pull.rebase = true;
          rebase.autoStash = true;
        }
        (lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {credential.helper = "osxkeychain";})
      ];
    };
  };
}
