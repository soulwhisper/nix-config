{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.dae;
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
    # : review, https://global.v2ex.co/t/1104684
    # :: conflict with mihomo/singbox
    networking.firewall.allowedTCPPorts = [1080 7890];

    environment.systemPackages = [pkgs.unstable.dae];

    systemd.tmpfiles.rules = [
      "d /var/lib/dae 0755 root root - -"
      "C /var/lib/dae/config.dae 0600 root root - ${./config.dae}"
      "d /usr/local/share/dae 0755 root root - -"
      "L+ /usr/local/share/dae/geoip.dat - - - - ${pkgs.geo-custom}/dae/geoip.dat"
      "L+ /usr/local/share/dae/geosite.dat - - - - ${pkgs.geo-custom}/dae/geosite.dat"
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
      wants = ["network-online.target"];
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        PIDFile = "/run/dae.pid";
        ExecStartPre = "${pkgs.unstable.dae}/bin/dae validate -c /var/lib/dae/config.dae";
        ExecStart = "${pkgs.unstable.dae}/bin/dae run --disable-timestamp -c /var/lib/dae/config.dae";
        ExecReload = "${pkgs.unstable.dae}/bin/dae reload $MAINPID";
        Restart = "always";
        RestartSec = 5;
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
      path = [pkgs.unstable.dae pkgs.gawk pkgs.curl pkgs.systemd];
      preStart = ''
        if [ -n "${cfg.subscription}" ] && [ -f "${cfg.subscription}" ]; then
          cat ${cfg.subscriptionFile} | awk -F= '{print $2}' > /var/lib/dae/sublist
        else
          echo "CHANGEME" > /var/lib/dae/sublist
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
        dae reload
      '';
    };
  };
}
