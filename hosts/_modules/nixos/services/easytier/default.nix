{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.modules.services.easytier;
  py-toml-merge =
    pkgs.writers.writePython3Bin "py-toml-merge"
    {
      libraries = with pkgs.python3Packages; [
        tomli-w
        mergedeep
      ];
    }
    ''
      import argparse
      from pathlib import Path
      from typing import Any

      import tomli_w
      import tomllib
      from mergedeep import merge

      parser = argparse.ArgumentParser(description="Merge multiple TOML files")
      parser.add_argument(
          "files",
          type=Path,
          nargs="+",
          help="List of TOML files to merge",
      )

      args = parser.parse_args()
      merged: dict[str, Any] = {}

      for file in args.files:
          with open(file, "rb") as fh:
              loaded_toml = tomllib.load(fh)
              merged = merge(merged, loaded_toml)

      print(tomli_w.dumps(merged))
    '';
  toml = pkgs.formats.toml {};
  mkConfig = toml.generate "config.toml" {
    instance_name = "default";
    dhcp = true;
    listeners = [
      "tcp://0.0.0.0:11010"
      "udp://0.0.0.0:11010"
      "wg://0.0.0.0:11011"
    ];
    rpc_portal = "0.0.0.0:15888";
    peer = map (peer: {uri = peer;}) (cfg.peers ++ cfg.public_nodes);
    proxy_network = map (proxy_network: {cidr = proxy_network;}) cfg.proxy_networks;
    flags = {
      enable_kcp_proxy = true;
      latency_first = true;
      relay_all_peer_rpc = true;
      relay_network_whitelist = "";
    };
  };
in {
  options.modules.services.easytier = {
    enable = lib.mkEnableOption "easytier";
    authFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };
    peers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    proxy_networks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    public_nodes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "tcp://public.easytier.top:11010"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [11010];
    networking.firewall.allowedUDPPorts = [11010 11011];

    environment.systemPackages = [pkgs.easytier-latest];

    systemd.services.easytier = {
      requires = ["network.target"];
      wantedBy = ["multi-user.target"];
      description = "Simple, decentralized mesh VPN with WireGuard support";
      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = 5;
        ExecStartPre = pkgs.writeShellScript "easytier-prestart" ''
          mkdir -p /var/lib/easytier
          ${lib.getExe py-toml-merge} '${mkConfig}' '${cfg.authFile}' |
          install -m 600 /dev/stdin /var/lib/easytier/config.toml
        '';
        ExecStart = "${lib.getExe pkgs.easytier-latest} -c /var/lib/easytier/config.toml --multi-thread";
      };
    };
  };
}
