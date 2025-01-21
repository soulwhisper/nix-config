{
  pkgs,
  flake-packages,
  ...
}: {
  config = {
    home.packages = with pkgs; [
      any-nix-shell
      binutils
      coreutils
      curl
      du-dust
      envsubst
      findutils
      fish
      gawk
      gnused
      gum
      jo
      jq
      tmux
      vim
      wget
      yq-go
    ];
  };
}
