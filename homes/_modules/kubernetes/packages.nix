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
    # kubefwd,
    # : archived krew plugins
    # cnpg,explore,kyverno,mayastor,neat,oidc-login,openebs,pgo,pv-migrate,

    home.packages =
      (with pkgs; [
        kubecolor-catppuccin
        kubectl-browse-pvc
        talhelper
        talosctl
      ])
      ++ (with pkgs.unstable; [
        cilium-cli
        fluxcd
        kubecm
        kubeconform
        kubecolor
        kubectl
        kubescape
        kustomize

        # optimization
        # krr # current broken
        popeye
      ])
      ++ [
        wrappedHelmPkg
        wrappedHelmfilePkg
      ];

    home.sessionVariables = {
      KUBECOLOR_CONFIG = "${pkgs.kubecolor-catppuccin}/catppuccin-${catppuccinCfg.flavor}.yaml";
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
        ${lib.getExe pkgs.unstable.kubecm} completion fish | source
      '';

      functions = {
        kyaml = {
          description = "Clean up kubectl get yaml output";
          body = ''
            kubectl get $argv -o yaml | kubectl neat
          '';
        };
      };
      shellAliases = {
        flux-local = "uvx flux-local";
        kubectl = "kubecolor";
        k = "kubectl";
        kc = "kubecm";
        ks = "kubescape";
      };
    };
  };
}
