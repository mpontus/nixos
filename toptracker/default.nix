{ pkgs ? import <nixpkgs> {} }: with pkgs; let
  deps = [
    stdenv.cc.cc
    glib
    xorg.libX11
    xorg.libXScrnSaver
    gtk2
    libappindicator-gtk2
    qt5.qtbase
    qt5.qtsvg
    qt5.qtmultimedia
  ];
in qt5.mkDerivation rec {
  pname = "toptracker";
  version = "1.6.2-6524";
  src = fetchurl {
      url = "https://d101nvfmxunqnl.cloudfront.net/desktop/builds/debian/toptracker_${version}_amd64.deb";
      sha256 = "b3d234f1aa5496ca8da0c1ef1b4b58880c4f19f527b520ebbf0faab0988e9061";
  };
  buildInputs = [dpkg which] ++ deps;

  unpackPhase = ''
    dpkg-deb -x $src unpacked
    mv unpacked/opt/toptracker $out
    cp -R unpacked/usr/share $out/
  '';
  
  installPhase = ''
    interpreter=$(patchelf --print-interpreter $(readlink -f $(which patchelf)))
    ldpath=${lib.makeLibraryPath deps}:$out/lib
    patchelf --set-interpreter $interpreter --set-rpath $ldpath $out/bin/TopTracker
    sed \
      -e "s!/opt/toptracker!$out!" \
      -e "s!/usr/bin/toptracker!$out/bin/toptracker!" \
      -i $out/share/applications/toptracker.desktop
    ln -s TopTracker $out/bin/toptracker
    ln -s bin/toptracker $out/toptracker
  '';
  
  qtWrapperArgs = [
    "--set" "QT_QPA_PLATFORM" "xcb"
    "--unset" "XDG_SESSION_TYPE"
  ];

  dontStrip = true;
  dontPatchELF = true;
}
