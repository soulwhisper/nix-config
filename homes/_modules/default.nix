{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.krewfile.homeManagerModules.krewfile

    ./deployment
    ./development
    ./editor
    ./kubernetes
    ./security
    ./shell
    ./terminal
    ./themes
    ./mutability.nix
  ];

  config = {
    home.stateVersion = "25.05";

    programs.home-manager.enable = true;
    xdg.enable = true;
  };
}
