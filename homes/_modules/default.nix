{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.krewfile.homeManagerModules.krewfile

    ./deployment
    ./development
    ./kubernetes
    ./security
    ./shell
    ./terminal
    ./themes
  ];

  config = {
    home.stateVersion = "25.05";

    programs.home-manager.enable = true;
    xdg.enable = true;
  };
}
