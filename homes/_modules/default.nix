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
    home.stateVersion = "24.11";

    programs.home-manager.enable = true;
    xdg.enable = true;
  };
}
