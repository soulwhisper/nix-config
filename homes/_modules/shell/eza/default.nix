_:
{
  config = {
    programs.eza = {
      enable = true;
      icons = "auto";
      extraOptions = [
        "--all"
        "--long"
        "--group"
        "--header"
        "--total-size"
      ];
      enableBashIntegration = true;
      enableFishIntegration = true;
    };
  };
}
