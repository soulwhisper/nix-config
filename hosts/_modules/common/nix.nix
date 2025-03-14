{
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
in {
  nix = {
    registry = {
      stable.flake = inputs.nixpkgs;
      unstable.flake = inputs.nixpkgs-unstable;
    };
    channel.enable = false;

    optimise.automatic = true;

    settings = {
      # NIX_PATH is still used by many useful tools, so we set it to the same value as the one used by this flake
      # make `nix repl '<nixpkgs>'` use the same nixpkgs as the one used by this flake
      nix-path = "nixpkgs=${inputs.nixpkgs.outPath}";

      substituters = lib.mkIf isLinux [
        "https://soulwhisper.cachix.org"
        "https://nix-community.cachix.org"
        "https://numtide.cachix.org"
        "https://cache.garnix.io"
      ];

      trusted-public-keys = [
        "soulwhisper.cachix.org-1:GWSDjQwU45RQZwMmxiHKT/IDXsCoadlig+7CNCeocT4="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];

      # Fallback quickly if substituters are not available.
      connect-timeout = 5;

      # Enable flakes
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # The default at 10 is rarely enough.
      log-lines = lib.mkDefault 25;

      # Avoid disk full issues
      max-free = lib.mkDefault (1000 * 1000 * 1000);
      min-free = lib.mkDefault (128 * 1000 * 1000);

      # Avoid copying unnecessary stuff over SSH
      builders-use-substitutes = true;

      keep-outputs = true;
      keep-derivations = false;

      # this makes sure to always check for new commits when fetching source
      tarball-ttl = 0;
    };

    # Add nixpkgs input to NIX_PATH
    nixPath = ["nixpkgs=${inputs.nixpkgs.outPath}"];

    # garbage collection
    gc = {
      automatic = true;
      options = "--delete-older-than 2d";
    };
  };
}
