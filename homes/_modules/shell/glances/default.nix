{pkgs, ...}: {
  config = {
    home.packages = [
      pkgs.unstable.glances
    ];

    programs.fish.shellAliases = {
      top = "glances";
    };
  };
}
