{
  pkgs,
  inputs,
  ...
}:

inputs.nixvim.legacyPackages.${pkgs.system}.makeNixvimWithModule {
  inherit pkgs;
  extraSpecialArgs = {};
  module = {
    imports = [ ../homes/soulwhisper/config/editor/nvim ];
  };
}
