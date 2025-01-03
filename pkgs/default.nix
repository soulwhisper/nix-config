# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'
{
  inputs,
  pkgs ? import <nixpkgs> {},
  ...
}:
{
  caddy-custom = pkgs.callPackage ./caddy-custom {};
  easytier-custom = pkgs.callPackage ./easytier-custom {};
  hass-sgcc = pkgs.callPackage ./hass-sgcc {};
  kubecolor-catppuccin = pkgs.callPackage ./kubecolor-catppuccin {};
  # kubectl-browse-pvc = pkgs.callPackage ./kubectl-browse-pvc {};
  # kubectl-klock = pkgs.callPackage ./kubectl-klock {};
  # kubectl-mayastor = pkgs.callPackage ./kubectl-mayastor {};
  # kubectl-netshoot = pkgs.callPackage ./kubectl-netshoot {};
  kubectl-pgo = pkgs.callPackage ./kubectl-pgo {};
  shcopy = pkgs.callPackage ./shcopy {};
  talhelper = inputs.talhelper.packages.${pkgs.system}.default;
  talosctl = pkgs.callPackage ./talosctl {};
  talos-api = pkgs.callPackage ./talos-api {};
  usage = pkgs.callPackage ./usage {};
}