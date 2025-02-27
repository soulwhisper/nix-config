{
  config,
  lib,
  pkgs,
  ...
}: let
  bindfsConfig = lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.str;
        description = "the source path";
      };

      dest = lib.mkOption {
        type = lib.types.str;
        description = "the mount path";
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = ''
          Bindfs extra arguments as a list of strings.
          Example: ["--perms=0000:u=rD", "--mirror-only=joe,@wheel"]
        '';
      };
    };
  };

  mkbindfsService = name: {
    source,
    dest,
    extraArgs,
    ...
  }: {
    description = "mount bindfs for ${name}";
    after = ["local-fs.target"];
    wantedBy = ["local-fs.target"];
    serviceConfig.Type = "forking";
    preStart = "${pkgs.coreutils}/bin/mkdir -p ${source} ${dest}";
    script = "${pkgs.bindfs}/bin/bindfs ${lib.concatStringsSep " " extraArgs} ${source} ${dest}";
  };
in {
  options.modules.services.bindfs = lib.mkOption {
    type = lib.types.attrsOf bindfsConfig;
    description = "Configuration for bindfs mounts.";
    default = {};
  };

  # lib.mapAttrs' (name: value: { name = newName; value = newValue; }) attrs
  config = {
    systemd.services =
      lib.mapAttrs'
      (name: cfg: {
        name = "${name}-bindfs";
        value = mkbindfsService name cfg;
      })
      config.modules.services.bindfs;
  };

  # Example usage:
  # modules.services.bindfs.appname = {
  #   source = "/opt/apps/appname";
  #   dest = "/var/lib/appname";
  #   extraArgs = ["--perms=0000:u=rD", "--mirror-only=joe,@wheel"];
  # };
}
