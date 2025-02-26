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

        version = "3.7.0";
        pkgName = "drata-agent";

        src = pkgs.fetchurl {
          url = "https://github.com/drata/agent-releases/releases/download/v${version}/Drata-Agent-linux.deb";
          hash = "sha256-PBS2z+Z1ATt11lC5K51GaSorbmCLSoSki+PgfE6ey2w=";
        };
      in
      {
        packages.${pkgName} = pkgs.stdenv.mkDerivation {
          pname = pkgName;
          inherit version src;

          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            makeWrapper
            dpkg
            asar
          ];

          buildInputs = with pkgs; [
            electron
            libappindicator-gtk3 # systray support
          ];

          unpackPhase = ''
            dpkg-deb -x $src .
          '';

          buildPhase = ''
            mkdir -p app
            asar extract opt/Drata\ Agent/resources/app.asar app
            sed -i "s#process\.resourcesPath#'$out/lib/drata-agent'#g" app/dist/main.js
            asar pack app opt/Drata\ Agent/resources/app.asar
          '';

          installPhase = ''
            mkdir -p $out/{bin,lib/drata-agent,share/applications/share/icons/hicolor}

            cp -r opt/Drata\ Agent/resources/app.asar $out/lib/drata-agent/

            mkdir -p $out/lib/drata-agent/lib/linux/bin
            cp opt/Drata\ Agent/resources/lib/linux/bin/osqueryi $out/lib/drata-agent/lib/linux/bin/

            cp usr/share/applications/drata-agent.desktop $out/share/applications/
            substituteInPlace $out/share/applications/drata-agent.desktop \
              --replace-fail 'Exec="/opt/Drata Agent/drata-agent" %U' "Exec=\"$out/bin/drata-agent\" %U"

            for size in 16 32 256 512; do
              mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
              cp usr/share/icons/hicolor/''${size}x''${size}/apps/drata-agent.png \
                $out/share/icons/hicolor/''${size}x''${size}/apps/drata-agent.png
            done

            makeWrapper ${pkgs.electron}/bin/electron $out/bin/drata-agent \
              --add-flags "$out/lib/drata-agent/app.asar"
          '';

          meta = with pkgs.lib; {
            description = "Lightweight tray application for compliance tracking";
            homepage = "https://github.com/drata/drata-agent";
            license = licenses.asl20;
            platforms = [ "x86_64-linux" ];
            maintainers = [];
          };
        };

        packages.default = self.packages.${system}.${pkgName};
      });
}
