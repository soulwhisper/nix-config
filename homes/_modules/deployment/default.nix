{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.deployment;
  rootCA = pkgs.callPackage ../../../pkgs/root-ca { };
  tools = pkgs.callPackage ../../../pkgs/deployment-tools { root-ca = rootCA; };
in
{
  options.modules.deployment.enable = lib.mkEnableOption "portable controller deployment and offline PKI tools";

  config = lib.mkIf cfg.enable {
    home.packages = [ tools ];
    programs.fish = {
      enable = true;
      functions = {
        rca = {
          description = "Offline root authority (explicit state and approval)";
          body = "command ${tools}/bin/root-ca $argv";
        };
        pki = {
          description = "Controller intermediate preparation and PKI maintenance";
          body = "command ${tools}/bin/pki-admin $argv";
        };
        deploy = {
          description = "Pinned and explicitly approved NixOS deployment";
          body = "command ${tools}/bin/deploymentctl $argv";
        };
        fjo = {
          description = "Forgejo maintenance through the target executor";
          body = "command ${tools}/bin/forgejo-admin $argv";
        };
      };
      interactiveShellInit = lib.mkAfter ''
        complete -c root-ca -f -n '__fish_use_subcommand' -a 'init import export status fingerprint verify intermediate crl backup restore rollover retire'
        complete -c root-ca -l state -r -a '(__fish_complete_directories)'
        complete -c pki-admin -f -n '__fish_use_subcommand' -a 'generate validate stage revoke check backup restore'
        complete -c forgejo-admin -f -n '__fish_use_subcommand' -a 'doctor backup restore'
        complete -c deploymentctl -f -n '__fish_use_subcommand' -a 'build plan copy diff deploy activate status rollback'
        for tool in pki-admin forgejo-admin deploymentctl
          complete -c $tool -l help -s h -d 'Show command help'
          complete -c $tool -l target -r -d 'Explicit user@hostname; verified SSH host keys'
          complete -c $tool -l approve -r -d 'Exact explicit action approval'
        end
        for flag in directory certificate root identity sops-file private-key key-password-file
          complete -c pki-admin -l $flag -r -F
        end
        for flag in common-name recipient root-fingerprint
          complete -c pki-admin -l $flag -r
        end
        complete -c pki-admin -l reason -r -a '0 1 3 4 5 9' -d 'RFC5280 leaf revocation reason'
        for flag in repo plan out
          complete -c deploymentctl -l $flag -r -F
        end
        for flag in revision host system builder
          complete -c deploymentctl -l $flag -r
        end
        for tool in pki-admin forgejo-admin
          complete -c $tool -l backup -r -d 'Absolute encrypted archive path on target'
          complete -c $tool -l approve-backup -r -d 'Repeat the exact backup path to approve restore'
        end
        complete -c rca -w root-ca
        complete -c pki -w pki-admin
        complete -c deploy -w deploymentctl
        complete -c fjo -w forgejo-admin
      '';
    };
  };
}
