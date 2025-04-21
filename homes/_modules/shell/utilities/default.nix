{pkgs, ...}: {
  config = {
    home.packages = with pkgs; [
      any-nix-shell
      doggo
      jq
      wget
      yq-go

      unstable.glances
    ];

    # bat
    programs.bat.enable = true;

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

    # fish alias
    programs.fish.shellAliases = {
      cat = "bat";
      dig = "doggo";
      find = "fd";
      top = "glances";
    };
  };
}
