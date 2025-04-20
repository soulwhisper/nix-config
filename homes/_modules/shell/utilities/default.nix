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

    # themes
    catppuccin.bat.enable = true;

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

    # fish alias
    programs.fish.shellAliases = {
      cat = "bat";
      dig = "doggo";
      find = "fd";
      top = "glances";
    };
  };
}
