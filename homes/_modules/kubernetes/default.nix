{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.kubernetes;
  catppuccinCfg = config.modules.themes.catppuccin;

  # https://nixos.wiki/wiki/Helm_and_Helmfile
  wrappedHelmPkg = (pkgs.unstable.wrapHelm pkgs.unstable.kubernetes-helm {
    plugins = with pkgs.unstable.kubernetes-helmPlugins; [
      helm-diff
      helm-git
      helm-s3
      helm-secrets
      helm-unittest
    ];
  });
  wrappedHelmfilePkg = pkgs.unstable.helmfile-wrapped.override {
    inherit (wrappedHelmPkg) pluginsDir;
  };
in
{
  options.modules.kubernetes = {
    enable = lib.mkEnableOption "kubernetes";
  };

  config = lib.mkIf cfg.enable {
    home.packages = (with pkgs; [
      kubecolor-catppuccin
      kubectl-pgo
      talhelper
      talosctl
    ]) ++
    (with pkgs.unstable; [
      cilium-cli
      fluxcd
      kubecm
      kubeconform
      kubecolor
      kubectl
    ]) ++
    [
      wrappedHelmPkg
      wrappedHelmfilePkg
    ];

    home.sessionVariables = {
      KUBECOLOR_CONFIG = "${pkgs.kubecolor-catppuccin}/catppuccin-${catppuccinCfg.flavor}.yaml";
    };

    programs.krewfile = {
      enable = true;
      indexes = {
        netshoot = "https://github.com/nilic/kubectl-netshoot.git";
      };
      plugins = [
        # accessibility
        "browse-pvc"
        "pv-migrate"
        "mayastor"
        "oidc-login"
        "view-secret"

        # debug
        "explore"
        "klock"
        "neat"
        "netshoot/netshoot"
        "stern"

        # optimising
        "kubescape"
        "popeye"
        "resource-capacity"
        "score"

        # multi-clusters
        "karmada"

        # ml
        "kuberay"

      ];
    };

    catppuccin.k9s.enable = true;
    programs.k9s = {
      enable = true;
      package = pkgs.unstable.k9s;
      
      aliases = {
        aliases = {
          dp = "deployments";
          sec = "v1/secrets";
          jo = "jobs";
          cr = "clusterroles";
          crb = "clusterrolebindings";
          ro = "roles";
          rb = "rolebindings";
          np = "networkpolicies";
        };
      };

      settings = {
        k9s = {
          liveViewAutoRefresh = false;
          refreshRate = 2;
          maxConnRetry = 5;
          readOnly = false;
          noExitOnCtrlC = false;
          ui = {
            enableMouse = false;
            headless = false;
            logoless = false;
            crumbsless = false;
            reactive = false;
            noIcons = false;
          };
          skipLatestRevCheck = false;
          disablePodCounting = false;
          shellPod = {
            image = "busybox";
            namespace = "default";
            limits = {
              cpu = "100m";
              memory = "100Mi";
            };
          };
          imageScans = {
            enable = false;
            exclusions = {
              namespaces = [];
              labels = {};
            };
          };
          logger = {
            tail = 100;
            buffer = 5000;
            sinceSeconds = -1;
            fullScreen = false;
            textWrap = false;
            showTime = false;
          };
          thresholds = {
            cpu = {
              critical = 90;
              warn = 70;
            };
            memory = {
              critical = 90;
              warn = 70;
            };
          };
        };
      };
    };

    programs.fish = {
      interactiveShellInit = ''
        ${lib.getExe pkgs.unstable.kubecm} completion fish | source
      '';

      functions = {
        kyaml = {
          description = "Clean up kubectl get yaml output";
          body = ''
            kubectl get $argv -o yaml | kubectl-neat
          '';
        };
      };
      shellAliases = {
        kubectl = "kubecolor";
        k = "kubectl";
        kc = "kubecm";
      };
    };
  };
}
