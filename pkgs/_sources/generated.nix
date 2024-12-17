# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  caddy-core = {
    pname = "caddy-core";
    version = "v2.8.4";
    src = fetchFromGitHub {
      owner = "caddyserver";
      repo = "caddy";
      rev = "v2.8.4";
      fetchSubmodules = false;
      sha256 = "sha256-CBfyqtWp3gYsYwaIxbfXO3AYaBiM7LutLC7uZgYXfkQ=";
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
    version = "v0.5.0";
    src = fetchFromGitHub {
      owner = "CrunchyData";
      repo = "postgres-operator-client";
      rev = "v0.5.0";
      fetchSubmodules = false;
      sha256 = "sha256-JX+V8xYtvvzfsxjxWMB8YgF+2QgALdedHwxQ5J+a1+c=";
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
    version = "v1.0.8";
    src = fetchFromGitHub {
      owner = "siderolabs";
      repo = "discovery-service";
      rev = "v1.0.8";
      fetchSubmodules = false;
      sha256 = "sha256-WJ77SgMsVIkvTQRPAqNle0QWPyudk5iVvok9F4nvPp8=";
    };
  };
  talosctl = {
    pname = "talosctl";
    version = "v1.9.0";
    src = fetchFromGitHub {
      owner = "siderolabs";
      repo = "talos";
      rev = "v1.9.0";
      fetchSubmodules = false;
      sha256 = "sha256-j/GqAUP3514ROf64+ouvCg//9QuGoVDgxkNFqi4r+WE=";
    };
  };
  usage = {
    pname = "usage";
    version = "v1.6.0";
    src = fetchFromGitHub {
      owner = "jdx";
      repo = "usage";
      rev = "v1.6.0";
      fetchSubmodules = false;
      sha256 = "sha256-tKwJYVQYNh6m50Dx/s8KSS4qSU6JYnurL33RWX5g2ow=";
    };
  };
}
