## vscode

- flake.nix;

```shell
    # VSCode community extensions
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

- need `mutability.nix` to work;
- nix version is deprecated, use homebrew instead;
