{pkgs, ...}: {
  config = {
    home.packages = with pkgs; [
      any-nix-shell
      doggo
      httpie
      jq
      wget
      yq-go
      viddy
      unstable.glances
    ];

    # bat
    programs.bat = {
      enable = true;
      config = {
        pager = "never";
        style = "plain";
      };
    };

    # direnv; preferred over 'mise'
    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
      config.global.warn_timeout = 0;
    };

    # eza
    programs.eza = {
      enable = true;
      extraOptions = [
        "--all"
        "--group"
        "--group-directories-first"
        "--header"
        "--long"
        "--total-size"
      ];
    };

    # fd
    programs.fd = {
      enable = true;
      hidden = true;
      extraOptions = [
        "--no-ignore"
        "--absolute-path"
      ];
    };

    # fzf
    programs.fzf = {
      enable = true;
      package = pkgs.unstable.fzf;
      changeDirWidgetCommand = "fd --type d"; # alt + c
      changeDirWidgetOptions = [
        "--height=40%"
        "--preview 'eza --color=always --follow-symlinks --tree {} | head -200'"
      ];
      defaultCommand = "fd --type f";
      defaultOptions = [
        "--layout=reverse"
        "--height=100%"
        "--style=full"
        "--preview 'bat --color=always {}'"
      ];
      fileWidgetCommand = "fd --type f"; # ctrl + t
      fileWidgetOptions = [
        "--height=40%"
        "--preview 'bat --color=always {}'"
      ];
    };

    # ripgrep
    programs.ripgrep = {
      enable = true;
      arguments = [
        "--colors=line:style:bold"
        "--max-columns-preview"
      ];
    };

    # tealdeer
    programs.tealdeer = {
      enable = true;
      enableAutoUpdates = false;
      settings.display.use_pager = true;
    };

    # fish alias
    programs.fish.shellAliases = {
      cat = "bat";
      dig = "doggo";
      find = "fd";
      grep = "rg";
      top = "glances";
      watch = "viddy --disable_auto_save --differences --interval 2 --shell fish";
    };
  };
}
