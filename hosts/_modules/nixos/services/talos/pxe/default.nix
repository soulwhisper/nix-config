{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.talos.support.pxe;
in
{
  options.modules.services.talos.support.pxe = {
    enable = lib.mkEnableOption "talos-pxe";
  };

  config = lib.mkIf cfg.enable {
    # networking.firewall.allowedTCPPorts = [ 9301 ];
    networking.firewall.allowedUDPPorts = [ 67 69 4011 ];

    environment.etc = {
      "talos-pxe/dnsmasq.conf".source = pkgs.writeText "dnsmasq-config" (builtins.readFile ./dnsmasq.conf);
      "/etc/talos-pxe/dnsmasq.conf".mode = "0644";

      "talos-pxe/assets/README".source = pkgs.writeText "machbox-assets" (builtins.readFile ./assets/README);
      "/etc/talos-pxe/assets/README".mode = "0644";

      "talos-pxe/configs/groups/group-template.json".source = pkgs.writeText "machbox-configs-groups" (builtins.readFile ./configs/groups/group-template.json);
      "/etc/talos-pxe/configs/groups/group-template.json".mode = "0644";

      "talos-pxe/configs/profiles/profile-template.json".source = pkgs.writeText "machbox-configs-profiles" (builtins.readFile ./configs/profiles/profile-template.json);
      "/etc/talos-pxe/configs/profiles/profile-template.json".mode = "0644";

      "talos-pxe/tftpboot/undionly.kpxe".source = ./tftpboot/undionly.kpxe;
      "/etc/talos-pxe/tftpboot/undionly.kpxe".mode = "0644";

      "talos-pxe/tftpboot/undionly.kpxe.0".source = ./tftpboot/undionly.kpxe;
      "/etc/talos-pxe/tftpboot/undionly.kpxe.0".mode = "0644";

      "talos-pxe/tftpboot/ipxe.efi".source = ./tftpboot/ipxe.efi;
      "/etc/talos-pxe/tftpboot/ipxe.efi".mode = "0644";
    };

    services.dnsmasq = {
      enable = true;
      settings = {
        dhcp-leasefile = "/etc/talos-pxe/dnsmasq.leases";
        conf-file = "/etc/talos-pxe/dnsmasq.conf";
      };
    };

    systemd.services.matchbox-server = {
      description = "PXE bootstrap support for talos";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart ="${lib.getExe pkgs.matchbox-server} -address=0.0.0.0:9301 -assets-path=/etc/talos-pxe/assets -log-level=debug";
        WorkingDirectory = "/etc/talos-pxe/configs";
        StateDirectory = "matchbox-server";
        RuntimeDirectory = "matchbox-server";
        RuntimeDirectoryMode = "0755";
        PrivateTmp = true;
        DynamicUser = true;
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        PrivateUsers = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        ProcSubset = "pid";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
      };
    };
  };
}
