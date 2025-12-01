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
    ./kubernetes
    ./security
    ./shell
    ./themes
  ];

  config = {
    home.stateVersion = "25.11";

    programs.home-manager.enable = true;
    xdg.enable = true;
  };
}
