# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'
{
  inputs,
  pkgs ? import <nixpkgs> {},
  ...
}: {
  caddy-custom = pkgs.callPackage ./caddy-custom {};
  easytier-latest = pkgs.callPackage ./easytier-latest {};
  hass-sgcc = pkgs.callPackage ./hass-sgcc {};
  kubecolor-catppuccin = pkgs.callPackage ./kubecolor-catppuccin {};
  kubectl-pgo = pkgs.callPackage ./kubectl-pgo {};
  talhelper = inputs.talhelper.packages.${pkgs.system}.default;
  talosctl = pkgs.callPackage ./talosctl {};
  talos-api = pkgs.callPackage ./talos-api {};
}
