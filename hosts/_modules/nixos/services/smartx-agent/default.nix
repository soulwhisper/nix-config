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

    systemd.services."smartx-agent" = {
      description = "SMTX VMTools guest agent";
      aliases = [ "SVT.service" ];
      wantedBy = [
        "multi-user.target"
        "dev-virtio\\x2dports-org.qemu.guest_agent.0.device"
      ];
      bindsTo = [ "dev-virtio\\x2dports-org.qemu.guest_agent.0.device" ];
      after = [ "dev-virtio\\x2dports-org.qemu.guest_agent.0.device" ];
      path = with pkgs; [
        bash
        coreutils
        findutils
        gawk
        gnugrep
        gnused
        gnutar
        gzip
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
