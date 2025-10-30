{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.kubernetes;
  catppuccinCfg = config.modules.themes.catppuccin;

  # https://nixos.wiki/wiki/Helm_and_Helmfile
  wrappedHelmPkg = pkgs.unstable.wrapHelm pkgs.unstable.kubernetes-helm {
    plugins = with pkgs.unstable.kubernetes-helmPlugins; [
      helm-diff
      helm-git
      helm-s3
      helm-secrets
      helm-unittest
    ];
  };
  wrappedHelmfilePkg = pkgs.unstable.helmfile-wrapped.override {
    inherit (wrappedHelmPkg) pluginsDir;
  };
in {
  config = lib.mkIf cfg.enable {
    # : archived packages
    # kubefwd,kubecm
    # : archived krew plugins
    # cnpg,explore,kyverno,mayastor,neat,oidc-login,openebs,pgo,pv-migrate,

    home.packages =
      (with pkgs; [
        kubecolor-catppuccin
        kubectl-switch
        talhelper
        talosctl
        viddy
      ])
      ++ (with pkgs.unstable; [
        cilium-cli
        fluxcd
        kubecolor
        kubectl
        kubescape
        kustomize
        popeye
        viddy
      ])
      ++ [
        wrappedHelmPkg
        wrappedHelmfilePkg
      ];

    home.sessionVariables = {
      KUBECOLOR_CONFIG = "${pkgs.kubecolor-catppuccin}/catppuccin-${catppuccinCfg.flavor}.yaml";
      KUBECONFIG_DIR = "${config.home.homeDirectory}/.kube/configs";
    };

    programs.krewfile = {
      enable = true;
      krewPackage = pkgs.unstable.krew;
      indexes = {
        default = "https://github.com/kubernetes-sigs/krew-index.git";
        netshoot = "https://github.com/nilic/kubectl-netshoot.git";
      };
      plugins = [
        # accessibility
        "browse-pvc"
        "rook-ceph"
        "view-secret"

        # debug
        "df-pv"
        "klock"
        "neat"
        "netshoot/netshoot"
        "stern"

        # optimization
        "resource-capacity"
      ];
    };

    programs.fish = {
      interactiveShellInit = ''
        ${lib.getExe pkgs.kubectl-switch} completion fish | source
      '';

      functions = {
        kyaml = {
          description = "Clean up kubectl get yaml output";
          body = ''
            kubectl get $argv -o yaml | kubectl neat
          '';
        };
        watch = {
          description = "Watch with fish alias support";
          body = ''
            if test (count $argv) -gt 0
              if type -q viddy
                command viddy --disable_auto_save --differences --interval 2 --shell fish $argv[1..-1]
              else
                command watch -x fish -c "$argv"
              end
            end
          '';
        };
      };
      shellAliases = {
        flux-local = "uvx flux-local";
        kubectl = "kubecolor";
        k = "kubectl";
        kc = "kubectl-switch context";
        kns = "kubectl-switch ns";
        ks = "kubescape";
      };
    };
  };
}
