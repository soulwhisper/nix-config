{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.bindfs;

  bindfsConfig = types.submodule {
    options = {
      source = mkOption {
        type = types.str;
        description = "the source path";
      };

      dest = mkOption {
        type = types.nullOr types.str;
        description = "where to mount the bindfs";
        default = null;
      };

      user = mkOption {
        type = types.str;
        description = "the user for the destination path";
      };

      group = mkOption {
        type = types.str;
        description = "the group for the destination path";
      };

      extraArgs = mkOption {
        type = types.nullOr types.str;
        description = "bindfs extra arguments";
      };

      wantedBy = mkOption {
        type = types.listOf types.str;
        description = "systemd objects that depend on this bindfs";
        default = [];
      };

      overlay = mkOption {
        type = types.bool;
        description = "whether the bindfs should manage the directory";
        default = false;
      };
    };
  };

  mkbindfsService = name: {
    source,
    dest,
    wantedBy,
    args,
    overlay,
    ...
  }: {
    description = "mount bindfs for ${name}";
    after = ["local-fs.target"];
    wantedBy = ["local-fs.target"] ++ wantedBy;

    serviceConfig.Type = "forking";

    preStart = with pkgs; ''
      # !overlay make sure folder exists
      ${optionalString (!overlay) ''
        ${coreutils}/bin/mkdir -p '${dest}'
      ''}
      # overlay set folder readonly
      ${optionalString overlay ''
          ${coreutils}/bin/mkdir -p '${source}'
          ${coreutils}/bin/chmod -R 000 ${"'${source}'"}
          ${coreutils}/bin/chown -R 0:0 ${"'${source}'"}
        # Ensure user and group mapping is correct for the destination directory
        ${coreutils}/bin/chown ${user}:${group} ${dest} || true
      ''}
    '';
    script = "${pkgs.bindfs}/bin/bindfs -u ${user} -g ${group} ${extraArgs} '${source}' '${
      if overlay
      then source
      else dest
    }'";
  };
in {
  options.modules.services.bindfs = mkOption {
    type = types.attrsOf bindfsConfig;
    description = "bindfs configuration";
    default = {};
  };

  config = {
    assertions =
      mapAttrsToList (key: val: {
        # XOR
        assertion =
          !((val.overlay && (val.dest != null))
            || (!val.overlay && (val.dest == null)));
        message = "${key}: the overlay and dest options conflict";
      })
      cfg;

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

  # usage example, in modules.services.appname, replaced by tmpfiles and dataDir
  #
  # config = lib.mkIf cfg.enable {
  # ...
  #   modules.services.bindfs.appname = {
  #     source = "/var/lib/appname";
  #     dest = "/opt/apps/appname";
  #     user = "appuser";
  #     group = "appuser";
  #     overlay = false;
  #     wantedBy = [ "appname.service" ];
  #   };
  # ...
  # }
}
