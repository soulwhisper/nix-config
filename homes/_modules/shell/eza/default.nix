_:
{
  config = {
    programs.eza = {
      enable = true;
      icons = "auto";
      extraOptions = [
        "--group -l -a"
      ];
      enableBashIntegration = true;
      enableFishIntegration = true;
    };
  };
}
