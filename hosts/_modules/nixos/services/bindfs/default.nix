{
  lib,
  pkgs,
  config,
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
        type = lib.types.str;
        default = "";
        description = ''
          bindfs extra arguments,
          use `--perms=0000:u=rD` to mount readonly,
          use `--mirror-only=joe,@wheel` to share files.
        '';
      };
    };
  };

  mkbindfsService = name: {
    source,
    dest,
    args,
    ...
  }: {
    description = "mount bindfs for ${name}";
    after = ["local-fs.target"];
    wantedBy = ["local-fs.target"];
    serviceConfig.Type = "forking";
    preStart = "${pkgs.coreutils}/bin/mkdir -p ${source} ${dest}";
    script = "${pkgs.bindfs}/bin/bindfs ${extraArgs} ${source} ${dest}";
  };
in {
  options.modules.services.bindfs = mkOption {
    type = types.attrsOf bindfsConfig;
    description = "bindfs configuration";
    default = {};
  };

  config = {
    systemd.services = let
      units =
        mapAttrs' (name: info: {
          name = "${name}-bindfs";
          value = mkbindfsService name info;
        })
        cfg;
    in
      units;
  };

  # usage example, source owned by root, dest owned by app;
  #
  #   modules.services.bindfs.appname = {
  #     source = "/opt/apps/appname";
  #     dest = "/var/lib/appname";
  #   };
}
