{
  description = "The Drata Agent is a lightweight tray application that runs in the background, reporting read-only data to Drata about it's machine's state for compliance tracking.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        pname = "drata-agent";
        version = "3.8.0";
      in
      {
        packages.${pname} = with pkgs; stdenv.mkDerivation {
          inherit pname version;

          src = fetchurl {
            url = "https://github.com/drata/agent-releases/releases/download/${version}/Drata-Agent-linux.deb";
            hash = "sha256-PSTx991BV2HeijTXzXnmOA966syClbA82ionNOfJjVA=";
          };

          dontConfigure = true;
          dontBuild = true;

          nativeBuildInputs = [
            dpkg
            makeWrapper
            asar
          ];

          buildInputs = [
            gtk3
            libnotify
            nss
            xorg.libXScrnSaver
            xorg.libXtst
            xdg-utils
            at-spi2-core
            libuuid
            libsecret
            libappindicator-gtk3 # systray support
          ];

          preInstall = ''
            asar extract opt/Drata\ Agent/resources/app.asar app
            rm opt/Drata\ Agent/resources/app.asar
            substituteInPlace app/dist/main.js \
              --replace-fail "process.resourcesPath" "'$out/lib/drata-agent'"
            asar pack app opt/Drata\ Agent/resources/app.asar
            rm -rf app
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/share/drata-agent
            ls -al opt/*
            ls -al usr/*
            cp -r usr/share $out/
            cp -r opt/Drata\ Agent/resources/* $out/share/drata-agent/

            runHook postInstall
          '';

          preFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
            makeWrapper ${lib.getExe electron} $out/bin/drata-agent \
              --add-flags $out/share/drata-agent/app.asar \
              --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
              --set-default ELECTRON_FORCE_IS_PACKAGED 1 \
              --set-default ELECTRON_IS_DEV 0 \
              --inherit-argv0
          '';

          # installPhase = ''
          #   runHook preInstall
          #
          #   mkdir -p $out/{bin,lib/drata-agent,share/applications/share/icons/hicolor}
          #
          #   cp -r opt/Drata\ Agent/resources/app.asar $out/lib/drata-agent/
          #
          #   mkdir -p $out/lib/drata-agent/lib/linux/bin
          #   cp opt/Drata\ Agent/resources/lib/linux/bin/osqueryi $out/lib/drata-agent/lib/linux/bin/
          #
          #   cp usr/share/applications/drata-agent.desktop $out/share/applications/
          #   substituteInPlace $out/share/applications/drata-agent.desktop \
          #     --replace-fail 'Exec="/opt/Drata Agent/drata-agent" %U' "Exec=\"$out/bin/drata-agent\" %U"
          #
          #   for size in 16 32 256 512; do
          #     mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
          #     cp usr/share/icons/hicolor/''${size}x''${size}/apps/drata-agent.png \
          #       $out/share/icons/hicolor/''${size}x''${size}/apps/drata-agent.png
          #   done
          #
          #   makeWrapper ${electron}/bin/electron $out/bin/drata-agent \
          #     --add-flags "$out/lib/drata-agent/app.asar"
          #
          #   runHook postInstall
          # '';


          meta = with pkgs.lib; {
            description = "Lightweight tray application for compliance tracking";
            homepage = "https://github.com/drata/drata-agent";
            license = licenses.asl20;
            platforms = [ "x86_64-linux" ];
            sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
          };
        };

        packages.default = self.packages.${system}.${pname};
      });
}
