{
  inputs,
  lib,
  pkgs,
  ...
}: {
  nix = {
    registry = {
      stable.flake = inputs.nixpkgs;
      unstable.flake = inputs.nixpkgs-unstable;
    };
    channel.enable = false;

    optimise.automatic = true;

    settings = {
      substituters =
        [
          "https://soulwhisper.cachix.org"
          "https://devenv.cachix.org"
          "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          "https://nix-community.cachix.org"
          "https://numtide.cachix.org"
        ];

      trusted-public-keys = [
        "soulwhisper.cachix.org-1:GWSDjQwU45RQZwMmxiHKT/IDXsCoadlig+7CNCeocT4="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      ];

      # Fallback quickly if substituters are not available.
      connect-timeout = 5;

      # Enable features
      experimental-features = [
        "configurable-impure-env"
        "nix-command"
        "flakes"
      ];

      # Enable goproxy
      impure-env = ''
        "GOPROXY=https://goproxy.cn,direct"
      '';

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
