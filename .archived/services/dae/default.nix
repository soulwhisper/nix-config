{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.dae;
  configFile = ./config.dae;
  daePackage = pkgs.unstable.dae.overrideAttrs (oldAttrs: {
    postPatch =
      (oldAttrs.postPatch or "")
      + ''
        substituteInPlace common/netutils/dns.go \
          --replace-warn "208.67.222.222:5353" "8.8.8.8:53"
      '';
  });
in {
  options.modules.services.dae = {
    enable = lib.mkEnableOption "dae";
    subscriptionFile = lib.mkOption {
      type = lib.types.str;
      default = null;
      description = "The Shadowsocks links for the dae subscription.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.modules.services.mihomo.enable;
        message = "dae conflicts with mihomo TUN";
      }
    ];

    networking.firewall.allowedTCPPorts = [1080];

    environment.defaultPackages = [daePackage];

    systemd.tmpfiles.rules = [
      "d /var/lib/dae 0755 root root - -"
      "C /var/lib/dae/config.dae 0600 root root - ${configFile}"
    ];

    services.tinyproxy = {
      enable = true;
      settings = {
        Port = 1080;
        Listen = "0.0.0.0";
      };
    };

    systemd.services.dae = {
      description = "Dae Service";
      documentation = ["https://github.com/daeuniverse/dae"];
      wants = ["network-online.target"];
      after = ["network-online.target" "systemd-sysctl.service" "dbus.service"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        PIDFile = "/run/dae.pid";
        ExecStartPre = "${daePackage}/bin/dae validate -c /var/lib/dae/config.dae";
        ExecStart = "${daePackage}/bin/dae run --disable-timestamp -c /var/lib/dae/config.dae";
        ExecReload = "${daePackage}/bin/dae reload $MAINPID";
        Restart = "always";
      };
    };

    systemd.timers.update-dae-subs = {
      description = "Run Update DAE Subscription Script Periodically";
      timerConfig = {
        OnBootSec = "15min";
        OnUnitActiveSec = "12h";
        Unit = "update-dae-subs.service";
      };
      wantedBy = ["timers.target"];
    };

    systemd.services.update-dae-subs = {
      description = "Update DAE Subscription Service";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      path = [daePackage pkgs.curl pkgs.systemd];
      preStart = ''
        if [ -n "${cfg.subscriptionFile}" ] && [ -f "${cfg.subscriptionFile}" ]; then
          cat ${cfg.subscriptionFile} | awk -F= '{print $2}' > /var/lib/dae/sublist
        else
          echo "CHANGEME" > /var/lib/daesublist
        fi
      '';
      script = ''
        cd /var/lib/dae

        sed -e 's/^ *//g' -e 's/ *$//g' -e 's/"//g' sublist > sublist.tmp

        version="$(dae --version | head -n 1 | sed 's/dae version //')"
        UA="dae/$version (like v2rayA/1.0 WebRequestHelper) (like v2rayN/1.0 WebRequestHelper)"
        line_number=1

        while IFS= read -r url
        do
          if [[ -z "$url" ]]; then
            continue
          fi

          file_name="subscription_$line_number.sub"

          if curl --retry 3 --retry-delay 5 -fL -A "$UA" "$url" -o "$file_name.new"; then
            mv "$file_name.new" "$file_name"
            chmod 0600 "$file_name"
            echo "Downloaded $file_name from $url"
          else
            rm -f "$file_name.new"
            echo "Failed to download $file_name from $url"
          fi

          line_number=$((line_number + 1))
        done < sublist.tmp

        rm -f sublist.tmp

        if curl --retry 3 --retry-delay 5 -fL "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat" -o "geoip.dat.new"; then
          mv "geoip.dat.new" "geoip.dat"
          chmod 0600 "geoip.dat"
          echo "Downloaded latest geoip.dat."
        else
          rm -f "geoip.dat.new"
          echo "Failed to download latest geoip.dat."
        fi

        if curl --retry 3 --retry-delay 5 -fL "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat" -o "geosite.dat.new"; then
          mv "geosite.dat.new" "geosite.dat"
          chmod 0600 "geosite.dat"
          echo "Downloaded latest geosite.dat."
        else
          rm -f "geosite.dat.new"
          echo "Failed to download latest geosite.dat."
        fi

        dae reload
        if [ $? -ne 0 ]; then
          echo "Reload failed, restarting dae..."
          systemctl restart dae
        else
          echo "Reload succeeded."
        fi
      '';
    };
  };
}
