# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'
{
  inputs,
  pkgs ? import <nixpkgs> {},
  ...
}: {
  caddy-custom = pkgs.callPackage ./caddy-custom {};
  hass-sgcc = pkgs.callPackage ./hass-sgcc {};
  kubecolor-catppuccin = pkgs.callPackage ./kubecolor-catppuccin {};
  kubectl-switch = pkgs.callPackage ./kubectl-switch {};
  rime-moqi-yinxing = pkgs.callPackage ./rime-moqi-yinxing {};
  talhelper = inputs.talhelper.packages.${pkgs.stdenv.hostPlatform.system}.default;
  talosctl = pkgs.callPackage ./talosctl {};
  talos-api = pkgs.callPackage ./talos-api {};
  zotregistry = pkgs.callPackage ./zotregistry {};
  zotregistry-ui = pkgs.callPackage ./zotregistry-ui {};
}
