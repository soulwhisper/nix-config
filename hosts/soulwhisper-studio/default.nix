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

    # Raise the GPU wired memory ceiling to 56GB (leaves ~8GB for macOS).
    # sysctl does not persist across reboots; this launchd daemon re-applies it
    # at every boot.
    launchd.daemons.iogpu-wired-limit = {
      script = ''
        /usr/sbin/sysctl iogpu.wired_limit_mb=57344
      '';
      serviceConfig = {
        RunAtLoad = true;
        KeepAlive = false;
      };
    };

    # Always-on inference server: never sleep, restart after power failure.
    system.activationScripts.postActivation.text = ''
      /usr/bin/pmset -a sleep 0 displaysleep 15 powernap 0 tcpkeepalive 1 autorestart 1 standby 0 hibernatemode 0
      # macOS updates must never reboot an inference box mid-session; updates
      # are attended events via the KVM console.
      /usr/sbin/softwareupdate --schedule off
    '';

    # NUT client config for the infra UPS (NUT server on the Synology NAS).
    # Written imperatively (root:wheel 0600) instead of environment.etc so the
    # credential never lands in the world-readable nix store.
    # TODO: migrate to sops once the studio host age key is enrolled.
    system.activationScripts.upsmonConf.text = ''
      /usr/bin/install -d -m 0755 /opt/homebrew/etc
      /bin/cat > /opt/homebrew/etc/upsmon.conf <<'EOF'
MONITOR ups@10.10.0.254 1 monuser secret secondary
SHUTDOWNCMD "/sbin/shutdown -h +0"
NOCOMMWARNTIME 300
FINALDELAY 5
EOF
      /usr/sbin/chown root:wheel /opt/homebrew/etc/upsmon.conf
      /bin/chmod 0600 /opt/homebrew/etc/upsmon.conf
    '';

    launchd.daemons = {
      # oMLX inference server. Runs at boot with no login session — the brew
      # formula's service block (user LaunchAgent) dies at the login window,
      # which is unusable on a headless box. Mirrors Formula/omlx.rb:
      #   run [opt_bin/"omlx", "serve"], keep_alive, working_dir var
      # Do NOT also `brew services start omlx` — that registers a second
      # instance on the same port.
      omlx = {
        script = ''
          export HOME=/Users/soulwhisper
          export PATH=/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin
          exec /opt/homebrew/bin/omlx serve
        '';
        serviceConfig = {
          UserName = "soulwhisper";
          WorkingDirectory = "/opt/homebrew/var";
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/opt/homebrew/var/log/omlx.log";
          StandardErrorPath = "/opt/homebrew/var/log/omlx.log";
        };
      };
      # UPS monitor: shuts the Mac down cleanly on NUT FSD/low-battery.
      # Prereq: NUT server must cut outlet power after client halt
      # (offdelay/shutdown.return) so autorestart=1 can fire on mains return.
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
      # Prometheus node exporter; scrape target lives in the cluster
      # prometheus, port per docs/services.md registry.
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
        {
          name = "jundot/omlx";
          trusted = true;
        }
      ];
      brews = [
        "omlx"
        "nut" # NUT client (upsmon); server is the infra UPS at 10.10.0.254
        "node_exporter" # prometheus metrics, listens on :9101
      ];
      casks = [
      ];
      masApps = {
      };
    };
  };
}
