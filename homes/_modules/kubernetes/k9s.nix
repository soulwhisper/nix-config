{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.kubernetes;
in {
  config = lib.mkIf cfg.enable {
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
          ui = {
            logoless = true;
          };
        };
      };
      plugins = {
        # ref:https://github.com/derailed/k9s/blob/master/plugins/resource-recommendations.yaml
        # in deployments/daemonsets/statefulsets view
        # Shift-K (no confirmation) to get resource recommendations

        # ref:https://github.com/derailed/k9s/blob/master/plugins/flux.yaml
        # move selected line to chosen resource in K9s, then:
        # Shift-R (no confirmation) to reconcile git-source or helmrelease or kustomization or helm-repo or oci-repo
        # Shift-S (no confirmation) to get all suspended helmreleases or kustomizations
        # Shift-T (with confirmation) to toggle suspend/resume a helmrelease or kustomization

        krr-resources = {
          shortCut = "Shift-K";
          confirm = false;
          description = "Get krr resource recommendations";
          scopes = ["deployments" "daemonsets" "statefulsets" "cronjobs"];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              LABELS=$(kubectl get $RESOURCE_NAME $NAME -n $NAMESPACE  --context $CONTEXT  --show-labels | awk '{print $NF}' | awk '{if(NR>1)print}')
              krr simple --cluster $CONTEXT --selector $LABELS
              echo "Press 'q' to exit"
              while : ; do
              read -n 1 k <&1
              if [[ $k = q ]] ; then
              break
              fi
              done
            ''
          ];
        };
        krr-ns = {
          shortCut = "Shift-K";
          confirm = false;
          description = "Get krr resource recommendations";
          scopes = ["namespaces"];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              krr simple --cluster $CONTEXT -n $RESOURCE_NAME
              echo "Press 'q' to exit"
              while : ; do
              read -n 1 k <&1
              if [[ $k = q ]] ; then
              break
              fi
              done
            ''
          ];
        };
        reconcile-git = {
          shortCut = "Shift-R";
          confirm = false;
          description = "Flux reconcile";
          scopes = ["helmreleases"];
          command = "gitrepositories";
          background = false;
          args = [
            "-c"
            ''
              flux
              reconcile source git
              --context $CONTEXT
              -n $NAMESPACE $NAME
              | less -K
            ''
          ];
        };
        reconcile-hr = {
          shortCut = "Shift-R";
          confirm = false;
          description = "Flux reconcile";
          scopes = ["helmreleases"];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              flux
              reconcile helmrelease
              --context $CONTEXT
              -n $NAMESPACE $NAME
              | less -K
            ''
          ];
        };
        reconcile-ks = {
          shortCut = "Shift-R";
          confirm = false;
          description = "Flux reconcile";
          scopes = ["kustomizations"];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              flux
              reconcile kustomization
              --context $CONTEXT
              -n $NAMESPACE $NAME
              | less -K
            ''
          ];
        };
        reconcile-helm-repo = {
          shortCut = "Shift-R";
          confirm = false;
          description = "Flux reconcile";
          scopes = ["helmrepositories"];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              flux
              reconcile source helm
              --context $CONTEXT
              -n $NAMESPACE $NAME
              | less -K
            ''
          ];
        };
        reconcile-oci-repo = {
          shortCut = "Shift-R";
          confirm = false;
          description = "Flux reconcile";
          scopes = ["ocirepositories"];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              flux
              reconcile source oci
              --context $CONTEXT
              -n $NAMESPACE $NAME
              | less -K
            ''
          ];
        };
        get-suspended-helmreleases = {
          shortCut = "Shift-S";
          confirm = false;
          description = "Get suspended Helmreleases";
          scopes = ["helmrelease"];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              kubectl get
              --context $CONTEXT
              --all-namespaces
              helmreleases.helm.toolkit.fluxcd.io -o json
              | jq -r '.items[] | select(.spec.suspend==true) | [.metadata.namespace,.metadata.name,.spec.suspend] | @tsv'
              | less -K
            ''
          ];
        };
        get-suspended-kustomizations = {
          shortCut = "Shift-S";
          confirm = false;
          description = "Get suspended Kustomizations";
          scopes = ["kustomizations"];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              kubectl get
              --context $CONTEXT
              --all-namespaces
              kustomizations.kustomize.toolkit.fluxcd.io -o json
              | jq -r '.items[] | select(.spec.suspend==true) | [.metadata.name,.spec.suspend] | @tsv'
              | less -K
            ''
          ];
        };
        toggle-helmrelease = {
          shortCut = "Shift-T";
          confirm = true;
          description = "Toggle to suspend or resume a HelmRelease";
          scopes = ["helmreleases"];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              suspended=$(kubectl --context $CONTEXT get helmreleases -n $NAMESPACE $NAME -o=custom-columns=TYPE:.spec.suspend | tail -1);
              verb=$([ $suspended = "true" ] && echo "resume" || echo "suspend");
              flux
              $verb helmrelease
              --context $CONTEXT
              -n $NAMESPACE $NAME
              | less -K
            ''
          ];
        };
        toggle-kustomization = {
          shortCut = "Shift-T";
          confirm = true;
          description = "Toggle to suspend or resume a Kustomization";
          scopes = ["hkustomizations"];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              suspended=$(kubectl --context $CONTEXT get kustomizations -n $NAMESPACE $NAME -o=custom-columns=TYPE:.spec.suspend | tail -1);
              verb=$([ $suspended = "true" ] && echo "resume" || echo "suspend");
              flux
              $verb kustomization
              --context $CONTEXT
              -n $NAMESPACE $NAME
              | less -K
            ''
          ];
        };
      };
    };
  };
}
