# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'
{
  inputs,
  pkgs ? import <nixpkgs> {},
  ...
} @_inputs:

{
  talhelper = inputs.talhelper.packages.${pkgs.system}.default;
  kubectl-browse-pvc = pkgs.callPackage ./kubectl-browse-pvc.nix {};
  kubectl-get-all = pkgs.callPackage ./kubectl-get-all.nix {};
  kubectl-netshoot = pkgs.callPackage ./kubectl-netshoot.nix {};
  kubectl-pgo = pkgs.callPackage ./kubectl-pgo.nix {};
  nvim = pkgs.callPackage ./nvim.nix _inputs;
  shcopy = pkgs.callPackage ./shcopy.nix {};
  usage = pkgs.callPackage ./usage.nix {};
}
