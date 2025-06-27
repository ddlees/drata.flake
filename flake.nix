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
            libappindicator-gtk3 # systray support
          ];

          preInstall = ''
            asar extract opt/Drata\ Agent/resources/app.asar app
            rm opt/Drata\ Agent/resources/app.asar
            substituteInPlace app/dist/main.js \
              --replace-fail "process.resourcesPath" "'$out/opt/Drata\ Agent/resources'"
            asar pack app opt/Drata\ Agent/resources/app.asar
            rm -rf app
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p "$out/bin"
            cp -R opt "$out"
            cp -R usr/share "$out/share"
            
            runHook postInstall
          '';

          preFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
            makeWrapper ${lib.getExe electron} $out/bin/drata-agent \
              --add-flags "$out/opt/Drata\ Agent/resources/app.asar" \
              --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
              --inherit-argv0
          '';

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
