{
  lib,
  config,
  ...
}:
let
  cfg = config.modules.services.backup;
in
{
  options.modules.services.backup = {
    dataDir = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
    };
  };

  # Notes about Backup
  #   * this general nix works for dataDir defination;
  #   * borg is removed due to nfs/samba/gitops/nix-config exists;
}