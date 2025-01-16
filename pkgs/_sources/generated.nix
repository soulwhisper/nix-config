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
    version = "89f16b99c18ef49c8bb470a82f895bce01cbaece";
    src = fetchFromGitHub {
      owner = "caddy-dns";
      repo = "cloudflare";
      rev = "89f16b99c18ef49c8bb470a82f895bce01cbaece";
      fetchSubmodules = false;
      sha256 = "sha256-XTNt2QfbKmt+Dryce8FRVhLrHdPkxhj0PPjCDijMuEs=";
    };
    date = "2024-07-03";
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
  shcopy = {
    pname = "shcopy";
    version = "v0.1.5";
    src = fetchFromGitHub {
      owner = "aymanbagabas";
      repo = "shcopy";
      rev = "v0.1.5";
      fetchSubmodules = false;
      sha256 = "sha256-MKlW8HrkXCYCOeO38F0S4c8mVbsG/VcZ+oGFC70amqQ=";
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
    version = "v1.9.2";
    src = fetchFromGitHub {
      owner = "siderolabs";
      repo = "talos";
      rev = "v1.9.2";
      fetchSubmodules = false;
      sha256 = "sha256-Cff++tGfKcpTaiBVTRZnNzExAHlq4UfkeiIDe3gOF3w=";
    };
  };
  usage = {
    pname = "usage";
    version = "v2.0.3";
    src = fetchFromGitHub {
      owner = "jdx";
      repo = "usage";
      rev = "v2.0.3";
      fetchSubmodules = false;
      sha256 = "sha256-bS8wMtmD7UPctP+8yDm8KylLIPzPuk6dt9ilWQzFvY0=";
    };
  };
}
