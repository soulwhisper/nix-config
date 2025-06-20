# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  caddy-core = {
    pname = "caddy-core";
    version = "v2.10.0";
    src = fetchFromGitHub {
      owner = "caddyserver";
      repo = "caddy";
      rev = "v2.10.0";
      fetchSubmodules = false;
      sha256 = "sha256-hzDd2BNTZzjwqhc/STbSAHnNlP7g1cFuMehqU1LumQE=";
    };
  };
  caddy-plugin-cloudflare = {
    pname = "caddy-plugin-cloudflare";
    version = "35fb8474f57d7476329f75d63eebafb95a93022f";
    src = fetchFromGitHub {
      owner = "caddy-dns";
      repo = "cloudflare";
      rev = "35fb8474f57d7476329f75d63eebafb95a93022f";
      fetchSubmodules = false;
      sha256 = "sha256-6Od+Ho2Tpn8dsm6fH5SxrGBND9Hfly2uZkTltgXzPE8=";
    };
    date = "2025-05-06";
  };
  hass-sgcc = {
    pname = "hass-sgcc";
    version = "v1.6.6";
    src = fetchFromGitHub {
      owner = "ARC-MX";
      repo = "sgcc_electricity_new";
      rev = "v1.6.6";
      fetchSubmodules = false;
      sha256 = "sha256-U4gGVjq13GKPfBzz+dTe9a/p6ZGCApIlox9vYogtMxA=";
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
  kubectl-browse-pvc = {
    pname = "kubectl-browse-pvc";
    version = "v1.3.0";
    src = fetchFromGitHub {
      owner = "clbx";
      repo = "kubectl-browse-pvc";
      rev = "v1.3.0";
      fetchSubmodules = false;
      sha256 = "sha256-8O36JLNfrh+/9JqJjeeSEO88uYkoo6OXCraK385tGvM=";
    };
  };
  poweradmin = {
    pname = "poweradmin";
    version = "v3.9.3";
    src = fetchFromGitHub {
      owner = "poweradmin";
      repo = "poweradmin";
      rev = "v3.9.3";
      fetchSubmodules = false;
      sha256 = "sha256-FtfnNin1kWqfLymn7ayZRLkbZXotovuOpCID0NfjiJQ=";
    };
  };
  talos-api = {
    pname = "talos-api";
    version = "v1.0.10";
    src = fetchFromGitHub {
      owner = "siderolabs";
      repo = "discovery-service";
      rev = "v1.0.10";
      fetchSubmodules = false;
      sha256 = "sha256-d0aSBtjfSctXn7repf0FwC53zG/9aSnvHRMZpiXCwuA=";
    };
  };
  talosctl = {
    pname = "talosctl";
    version = "v1.10.3";
    src = fetchFromGitHub {
      owner = "siderolabs";
      repo = "talos";
      rev = "v1.10.3";
      fetchSubmodules = false;
      sha256 = "sha256-smqQBFm33uTgK4RGtiu9wlgbHkt8jw7zeiVGWsHG/8s=";
    };
  };
  zotregistry = {
    pname = "zotregistry";
    version = "v2.1.5";
    src = fetchFromGitHub {
      owner = "project-zot";
      repo = "zot";
      rev = "v2.1.5";
      fetchSubmodules = false;
      sha256 = "sha256-MWmCttGYNvZBGFgR+em5dvId7rme7J7EZuSXKjlD0p8=";
    };
  };
  zotregistry-ui = {
    pname = "zotregistry-ui";
    version = "3dc49925d00381c2ac0b483285cb80f839df2dd2";
    src = fetchFromGitHub {
      owner = "project-zot";
      repo = "zui";
      rev = "3dc49925d00381c2ac0b483285cb80f839df2dd2";
      fetchSubmodules = false;
      sha256 = "sha256-e0k4P4KxQ6vpTgto9wdgg0aRRaelyLKh5qhQDEjY35M=";
    };
    date = "2025-06-14";
  };
}
