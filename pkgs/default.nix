# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'
{
  inputs,
  pkgs ? import <nixpkgs> {},
  ...
}: {
  caddy-custom = pkgs.callPackage ./caddy-custom {};
  geo-custom = pkgs.callPackage ./geo-custom {};
  hass-sgcc = pkgs.callPackage ./hass-sgcc {};
  kubecolor-catppuccin = pkgs.callPackage ./kubecolor-catppuccin {};
  kubectl-browse-pvc = pkgs.callPackage ./kubectl-browse-pvc {};
  rime-moqi-yinxing = pkgs.callPackage ./rime-moqi-yinxing {};
  talhelper = inputs.talhelper.packages.${pkgs.system}.default;
  talosctl = pkgs.callPackage ./talosctl {};
  talos-api = pkgs.callPackage ./talos-api {};
  zotregistry = pkgs.callPackage ./zotregistry {};
  zotregistry-ui = pkgs.callPackage ./zotregistry-ui {};
}
