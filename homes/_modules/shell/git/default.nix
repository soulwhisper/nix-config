{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.shell.git;
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
  };

  config = lib.mkIf cfg.enable {
    programs.gh.enable = true;
    programs.git = {
      enable = true;
      userName = cfg.username;
      userEmail = cfg.email;
      signing = {
        signByDefault = true;
        key = cfg.signingKey;
      };
      extraConfig = lib.mkMerge [
        cfg.config
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
        (lib.optionals pkgs.stdenv.hostPlatform.isDarwin {helper = "osxkeychain";})
      ];
    };
  };
}
