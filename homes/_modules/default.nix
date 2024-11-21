{
  pkgs,
  ...
}:
{
  imports = [
    ./deployment
    ./development
    ./editor
    ./kubernetes
    ./security
    ./shell
    ./themes
    ./mutability.nix
  ];

  config = {
    home.stateVersion = "23.11";

    programs = {
      home-manager.enable = true;
    };

    xdg.enable = true;

    home.packages = [
      pkgs.home-manager
    ];
  };
}
