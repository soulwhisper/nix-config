{
  lib,
  pkgs,
  ...
}: {
  modules = {
    development.vmware.enable = true;
  };
}
