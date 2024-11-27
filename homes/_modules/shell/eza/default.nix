_:
{
  config = {
    programs.eza = {
      enable = true;
      icons = "auto";
      extraOptions = [
        "-l -a"
      ];
      enableBashIntegration = true;
      enableFishIntegration = true;
    };
  };
}
