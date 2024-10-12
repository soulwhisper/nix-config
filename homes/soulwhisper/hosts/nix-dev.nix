{
  lib,
  pkgs,
  ...
}:
{
  modules = {
    development.enable = true;
    kubernetes.enable = true;
    security.gnugpg.enable = true;
    shell = {
      mise = {
        enable = true;
        package = pkgs.unstable.mise;
        globalConfig = {
          tools = {
            python = "latest";
          };
        };
      };
    };
  };
}
