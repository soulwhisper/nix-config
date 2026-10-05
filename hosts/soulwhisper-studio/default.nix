{
  hostname,
  pkgs,
  ...
}: {
  # Mac Studio · M5 Max · 64GB unified memory · local AI inference appliance.
  config = {
    networking = {
      computerName = "soulwhisper-studio";
      hostName = hostname;
      localHostName = hostname;
    };

    # install omlx via https://github.com/jundot/omlx/releases

    launchd.daemons.iogpu-wired-limit = {
      script = ''
        /usr/sbin/sysctl iogpu.wired_limit_mb=57344
      '';
      serviceConfig = {
        RunAtLoad = true;
        KeepAlive = false;
      };
    };

    system.activationScripts.postActivation.text = ''
      /usr/bin/pmset -a sleep 0 displaysleep 0 powernap 0 tcpkeepalive 1 autorestart 1 standby 0 hibernatemode 0
      /usr/sbin/softwareupdate --schedule off
    '';

    system.activationScripts.upsmonConf.text = ''
      /usr/bin/install -d -m 0755 /opt/homebrew/etc/nut
      /bin/cat > /opt/homebrew/etc/nut/upsmon.conf <<'EOF'
MONITOR ups@10.10.0.254 1 monuser secret secondary
SHUTDOWNCMD "/sbin/shutdown -h +0"
NOCOMMWARNTIME 300
FINALDELAY 5
EOF
      /usr/sbin/chown root:wheel /opt/homebrew/etc/nut/upsmon.conf
      /bin/chmod 0600 /opt/homebrew/etc/nut/upsmon.conf
    '';

    launchd.daemons = {
      upsmon = {
        script = ''
          exec /opt/homebrew/sbin/upsmon -F
        '';
        serviceConfig = {
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/opt/homebrew/var/log/upsmon.log";
          StandardErrorPath = "/opt/homebrew/var/log/upsmon.log";
        };
      };
      node-exporter = {
        script = ''
          exec /opt/homebrew/opt/node_exporter/bin/node_exporter --web.listen-address=":9101"
        '';
        serviceConfig = {
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/opt/homebrew/var/log/node_exporter.log";
          StandardErrorPath = "/opt/homebrew/var/log/node_exporter.log";
        };
      };
    };

    homebrew = {
      taps = [
      ];
      brews = [
        "nut"
        "node_exporter"
      ];
      casks = [
      ];
      masApps = {
      };
    };
  };
}
