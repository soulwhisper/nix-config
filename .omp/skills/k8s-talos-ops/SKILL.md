---
name: k8s-talos-ops
description: Use whenever the request involves a running Kubernetes cluster, Talos nodes, kubectl, kustomize, helm, or any K8s resource (pods, deployments, services, ingresses, CRDs). Trigger for casual mentions like "deploy this", "check the cluster", "scale up", "what's wrong with the pod", or any reference to a Talos node, a kubeconfig context, or a helm release. Pair with the `infra-operator` agent for anything mutating.
---

# Kubernetes + Talos operations

This skill assumes a Talos-based homelab cluster with kubectl-driven
deployments, optionally helm/kustomize. The user is solo, so blast radius
matters even at small scale.

## Always-first commands

```bash
# Confirm which cluster you're about to touch — single most common mistake.
kubectl config current-context

# Then orient.
kubectl get nodes -o wide
kubectl get pods -A | grep -vE 'Running|Completed'   # only the not-OK ones
```

If you don't see what you expected — wrong context. Stop before any further
command.

## Reading resources

```bash
kubectl get <kind> -n <ns>
kubectl describe <kind>/<name> -n <ns>
kubectl logs -n <ns> <pod> [-c <container>] [-f] [--previous]
kubectl get events -n <ns> --sort-by=.lastTimestamp | tail -20
```

For a workload that's misbehaving, the canonical triage order is:
`describe pod` (events) → `logs --previous` (crash before restart) →
`logs -f` (current).

## Mutating safely

Every mutation must go through diff → confirm → apply → verify.

```bash
# Manifest changes
kubectl diff  -f manifest.yaml          # show me the delta
kubectl apply -f manifest.yaml          # gated by omp's tool approval
kubectl rollout status deploy/<name> -n <ns>

# Kustomize
kustomize build overlays/<env> | kubectl diff  -f -
kustomize build overlays/<env> | kubectl apply -f -

# Helm
helm diff upgrade <release> <chart> -n <ns> -f values.yaml --install
helm upgrade     <release> <chart> -n <ns> -f values.yaml --install
helm history     <release> -n <ns>
helm rollback    <release> <revision> -n <ns>   # ← name your rollback path
```

Mutating commands are gated by omp's `tools.approval` settings.
The user will be prompted; don't try to suppress that.

## Talos-specific

Talos nodes are immutable; you mutate them by patching machine config.

```bash
talosctl -n <node> version
talosctl -n <node> get nodename
talosctl -n <node> dmesg | tail -50

# Diff before upgrading
talosctl -n <node> diff               # against the new machine config
talosctl -n <node> upgrade --image <ghcr.io/siderolabs/installer:vX.Y.Z>
talosctl -n <node> health
```

Never `talosctl reset` a node without naming the node explicitly in the
confirmation. There is no undo.

## Deleting things

Hard floor: do not delete a namespace, PVC, StatefulSet, or CRD without an
explicit user confirmation that names the resource (not just "yes, the
thing"). Side effects:

- Namespace deletion: cascades to every resource and lingers in `Terminating`
  if a finalizer is stuck — that's a separate triage path
  (`kubectl get … -o json | jq '.metadata.finalizers'`, then surgical
  patch).
- PVC deletion: depending on storage class, *deletes the volume*.
- StatefulSet deletion: pods go, PVCs may stay or may not (cascade policy).

## Read-only access

`~/.kube/config` and `~/.talos/config` are sensitive. omp's `tools.approval`
settings may restrict read access. Do not work around this; ask the user
to grant access for the current session if needed.

## Hand-offs

- For a change that's just YAML in git, with no live cluster yet → no
  cluster work needed, treat as ordinary code edit.
- For helm chart authoring → editing files in git, same as above.
- For Nix-managed kubeconfig contexts → `secrets-sops` skill.
- For "I'm scared this is going to break prod" → invoke `infra-operator`
  via `/ship`.
