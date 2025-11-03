{
  hostname,
  lib,
  pkgs,
  ...
}: {
  # ref:https://daiderd.com/nix-darwin/manual/index.html
  config = {
    networking = {
      computerName = "soulwhisper-mba";
      hostName = hostname;
      localHostName = hostname;
    };

    # : test/temp apps list

    environment.systemPackages = with pkgs; [
      # cardforge, https://github.com/Card-Forge/forge/releases
      unstable.forge-mtg.overrideAttrs
      (oldAttrs: {
        nativeBuildInputs = lib.lists.remove alsa-lib oldAttrs.nativeBuildInputs;
        preFixup = ''
          for commandToInstall in forge forge-adventure forge-adventure-editor; do
            chmod 555 $out/share/forge/$commandToInstall.sh
            PREFIX_CMD=""
            if [ "$commandToInstall" = "forge-adventure" ]; then
              PREFIX_CMD="--prefix LD_LIBRARY_PATH : ${
            super.lib.makeLibraryPath [
              super.libGL
            ]
          }"
            fi
            makeWrapper $out/share/forge/$commandToInstall.sh $out/bin/$commandToInstall \
            --prefix PATH : ${
            super.lib.makeBinPath [
              super.coreutils
              super.openjdk
              super.gnused
            ]
          } \
            --set JAVA_HOME ${super.openjdk}/lib/openjdk \
            --set SENTRY_DSN "" \
            $PREFIX_CMD
          done
        '';
      })
    ];

    homebrew = {
      taps = [
        "nikitabobko/tap"
      ];
      brews = [
      ];
      casks = [
        # :: storage
        "transmission"

        # :: productivity
        "audacity"
        "squirrel-app"
        "wireshark-app"

        # :: test
        "acorn"
        "betterdisplay"
        "bluestacks"
        "little-snitch"
        "maa"
        "stats"
        "vanilla"
      ];
      masApps = {
        "DevHub" = 6476452351;
        "ReadKit" = 1615798039;
        "iCost" = 1484262528;
        # "Passepartout" = 1433648537;
        # "StopTheMadness Pro" = 6471380298;
      };
    };
  };
}
