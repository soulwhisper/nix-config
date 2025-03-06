{pkgs, ...}: {
  fonts = {
    packages = with pkgs; [
      monaspace
    ];
  };
}
