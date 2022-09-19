{ pkgs ? import <nixpkgs> { } }:
with pkgs;
let
  pname = "piavpn";
  version = "3.1.2-06767";
  deps = [
    stdenv.cc.cc
    glibc
    libnl
    openssl
    libxkbcommon
    qt5.qtbase
    qt5.qtdeclarative
    qt5.qtquickcontrols2
    qt5.qtgraphicaleffects
  ];
in qt5.mkDerivation rec {
  inherit pname version;
  src = pkgs.fetchurl {
    url =
      "https://installers.privateinternetaccess.com/download/pia-linux-${version}.run";
    sha256 = "2d7b983beafb272b9d229b3838c24eb23a3d8e6edd84e257d406af057a1145e8";
  };
  buildInputs = [ which coreutils procps iproute2 shadow ] ++ deps;
  nativeBuildInputs = deps;
  patches = [ ./piavpn.patch ];

  unpackPhase = ''
    /bin/sh $src --noexec --target .
  '';

  configurePhase = ''
    interpreter=$(patchelf --print-interpreter $(readlink -f $(which patchelf)))
    ldpath=${lib.makeLibraryPath deps}:$out/opt/piavpn/lib

    for file in piafiles/bin/*; do
        if [ -x "$file" ]; then
          patchelf --set-interpreter $interpreter --set-rpath $ldpath $file || true
        fi
    done

    substituteInPlace install.sh \
      --replace "/opt/" "$out/opt/" \
      --replace "/usr/" "$out/usr/" \
      --replace "/bin/cp " "cp " \
      --replace "sudo " " "
  '';

  installPhase = ''
    LD_LIBRARY_PATH="$ldpath:$(pwd)/piafiles/lib" \
      sh install.sh --systemd || true
      # sh install.sh --skip-service || true

    mkdir -p $out/bin
    ln -s $out/opt/piavpn/bin/pia-{client,daemon} $out/bin/
    wrapQtAppsHook
  '';

  dontPatchELF = true;
}
