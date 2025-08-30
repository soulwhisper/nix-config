{
  config,
  lib,
  ...
}: let
  cfg = config.modules.services.openssh;
in {
  options.modules.services.openssh = {
    enable = lib.mkEnableOption "openssh";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [22];

    services.openssh = {
      enable = true;
      ports = [22];
      # Don't allow home-directory authorized_keys
      authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
      # Disable builtin sftp service
      allowSFTP = false;
      settings = {
        # Harden
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        # Automatically remove stale sockets
        StreamLocalBindUnlink = "yes";
        # Allow forwarding ports to everywhere
        GatewayPorts = "clientspecified";
      };
    };

    # Passwordless sudo when SSH'ing with keys
    security.pam.sshAgentAuth = {
      enable = true;
      authorizedKeysFiles = [
        "/etc/ssh/authorized_keys.d/%u"
      ];
    };
  };
}
