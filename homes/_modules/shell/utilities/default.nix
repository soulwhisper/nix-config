{
  pkgs,
  flake-packages,
  ...
}: {
  config = {
    home.packages = with pkgs; [
      any-nix-shell
      coreutils
      curl
      du-dust
      envsubst
      findutils
      gawk
      gnused
      jq
      wget
      yq-go
    ];
  };
}
