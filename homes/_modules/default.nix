{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.krewfile.homeManagerModules.krewfile

    ./customization
    ./development
    ./kubernetes
    ./security
    ./shell
    ./themes
  ];

  config = {
    home.stateVersion = "26.05";

    programs.home-manager.enable = true;
    xdg.enable = true;
  };
}
