_: {
  config = {
    programs.fd = {
      enable = true;
      hidden = true;
      extraOptions = [
        "--no-ignore"
        "--absolute-path"
      ];
    };
    programs.fish.shellAliases = {
      find = "fd";
    };
  };
}
