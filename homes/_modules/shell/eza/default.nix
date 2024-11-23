_:
{
  config = {
    programs.eza = {
      enable = true;
      icons = true;
      extraOptions = [
        "--group -l -a"
      ];
      enableBashIntegration = true;
      enableFishIntegration = true;
    };
  };
}
