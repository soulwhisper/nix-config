{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.krewfile.homeManagerModules.krewfile

    ./customization
    ./deployment
    ./development
    ./hyprland
    ./kubernetes
    ./security
    ./shell
    ./themes
  ];

  config = {
    home.stateVersion = "25.05";

    programs.home-manager.enable = true;
    xdg.enable = true;
  };
}
