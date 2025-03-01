# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  caddy-core = {
    pname = "caddy-core";
    version = "v2.9.1";
    src = fetchFromGitHub {
      owner = "caddyserver";
      repo = "caddy";
      rev = "v2.9.1";
      fetchSubmodules = false;
      sha256 = "sha256-XW1cBW7mk/aO/3IPQK29s4a6ArSKjo7/64koJuzp07I=";
    };
  };
  caddy-plugin-cloudflare = {
    pname = "caddy-plugin-cloudflare";
    version = "1fb64108d4debf196b19d7398e763cb78c8a0f41";
    src = fetchFromGitHub {
      owner = "caddy-dns";
      repo = "cloudflare";
      rev = "1fb64108d4debf196b19d7398e763cb78c8a0f41";
      fetchSubmodules = false;
      sha256 = "sha256-nLpiXMHTKTfmc5TBkPErkvXf/d2tWBlv2h4A+ELrraU=";
    };
    date = "2025-02-28";
  };
  easytier-latest = {
    pname = "easytier-latest";
    version = "v2.2.2";
    src = fetchFromGitHub {
      owner = "EasyTier";
      repo = "EasyTier";
      rev = "v2.2.2";
      fetchSubmodules = false;
      sha256 = "sha256-Heb2ax2yUuGmqzIjrqjHUL3QZoofp7ATrIEN27ZA/Zs=";
    };
  };
  hass-sgcc = {
    pname = "hass-sgcc";
    version = "v1.6.4";
    src = fetchFromGitHub {
      owner = "ARC-MX";
      repo = "sgcc_electricity_new";
      rev = "v1.6.4";
      fetchSubmodules = false;
      sha256 = "sha256-AYkvEWmDIGS1iYmBLeL8woVf5KcE2ypwcoeCVRQYeTY=";
    };
  };
  kubecolor-catppuccin = {
    pname = "kubecolor-catppuccin";
    version = "1d4c2888f7de077e1a837a914a1824873d16762d";
    src = fetchFromGitHub {
      owner = "vkhitrin";
      repo = "kubecolor-catppuccin";
      rev = "1d4c2888f7de077e1a837a914a1824873d16762d";
      fetchSubmodules = false;
      sha256 = "sha256-gTneUh6yMcH6dVKrH00G61a+apasu9tiMyYjvNdOiOw=";
    };
    date = "2024-05-24";
  };
  kubectl-pgo = {
    pname = "kubectl-pgo";
    version = "v0.5.1";
    src = fetchFromGitHub {
      owner = "CrunchyData";
      repo = "postgres-operator-client";
      rev = "v0.5.1";
      fetchSubmodules = false;
      sha256 = "sha256-0y1+goq9xFZYfHelUBJD/ZcEiDvRFx0sEweF1Q6N2uk=";
    };
  };
  talos-api = {
    pname = "talos-api";
    version = "v1.0.9";
    src = fetchFromGitHub {
      owner = "siderolabs";
      repo = "discovery-service";
      rev = "v1.0.9";
      fetchSubmodules = false;
      sha256 = "sha256-Mk0npXcSd3UmTlgAlkC/vgOJNVIHy/KV15Y3epRevYw=";
    };
  };
  talosctl = {
    pname = "talosctl";
    version = "v1.9.4";
    src = fetchFromGitHub {
      owner = "siderolabs";
      repo = "talos";
      rev = "v1.9.4";
      fetchSubmodules = false;
      sha256 = "sha256-gD9fIBILqSFExTIziNx6Hy6TpsBC90yHSfSDB9fhKwA=";
    };
  };
}
