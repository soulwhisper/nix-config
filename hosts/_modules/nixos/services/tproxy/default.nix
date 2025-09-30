{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.tproxy;
in {
  imports = [
    ./mosdns
    ./singbox
    ./nftables.nix
  ];

  options.modules.services.tproxy = {
    enable = lib.mkEnableOption "tproxy-stack";
  };

  # dns route: request -> adguard -> mosdns -> upstream
  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl = {
      # enable IPv4 and IPv6 forwarding on all interfaces
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };
  };
}
