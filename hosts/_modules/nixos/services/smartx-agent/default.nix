{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.services."smartx-agent";

  isoDir = "/mnt/iso";
  stateDir = "/var/lib/smartx-agent";
  agentLink = "/opt/svt";

  warmup = pkgs.writeShellScript "smartx-agent-warmup" (builtins.readFile ./warmup.sh);
in
{
  options.modules.services."smartx-agent" = {
    enable = lib.mkEnableOption "the SmartX HCI guest agent (SMTX VMTools)";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.services.qemuGuest.enable;
        message = "modules.services.smartx-agent replaces qemu-guest-agent; set services.qemuGuest.enable = false.";
      }
    ];

    # HCI runs its guest-side probes as `/bin/bash -c ...`. NixOS only
    # creates /bin/sh, so every guest-exec fails with ENOENT and HCI never
    # receives the static VM data (address, gateway, DNS, ...).
    systemd.tmpfiles.rules = [
      "L+ /bin/bash - - - - ${pkgs.bashInteractive}/bin/bash"
    ];

    systemd.services."smartx-agent" = {
      description = "SMTX VMTools guest agent";
      aliases = [ "SVT.service" ];
      wantedBy = [
        "multi-user.target"
        "dev-virtio\\x2dports-org.qemu.guest_agent.0.device"
      ];
      bindsTo = [ "dev-virtio\\x2dports-org.qemu.guest_agent.0.device" ];
      after = [ "dev-virtio\\x2dports-org.qemu.guest_agent.0.device" ];
      # HCI's probes are ordinary distro shell scripts; give them the
      # same network/process/disk commands a stock Linux would provide.
      path = with pkgs; [
        bash
        coreutils
        findutils
        gawk
        gnugrep
        gnused
        gnutar
        gzip
        iproute2
        net-tools
        procps
        systemd
        util-linux
        which
      ];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        Type = "simple";
        UMask = "0077";
        StateDirectory = "smartx-agent";
        StateDirectoryMode = "0700";
        TimeoutStartSec = "5min";
        Environment = [
          "SMARTX_AGENT_ISO=${isoDir}"
          "SMARTX_AGENT_STATE_DIR=${stateDir}"
          "SMARTX_AGENT_LINK=${agentLink}"
        ];
        ExecStartPre = warmup;
        ExecStart = "${agentLink}/qemu-ga --method=virtio-serial --path=/dev/virtio-ports/org.qemu.guest_agent.0 --blacklist= --fsfreeze-hook=${agentLink}/fsfreeze-hook --pidfile=${agentLink}/run/svt.pid --statedir=${agentLink}/run --logfile=/var/log/svt.log";
        Restart = "always";
        RestartSec = 10;
      };
    };
  };
}
