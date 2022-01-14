# -*- compile-command: "nix-build"; eval: (add-hook 'after-save-hook 'recompile nil t); -*-
{ pkgs ? import <nixpkgs> {} }: with pkgs; let
  deps = [
    stdenv.cc.cc
    glib
    glibc
    libnl
    openssl
    libxkbcommon
    xorg.libX11
    xorg.libXScrnSaver
    xorg.libXext
    xorg.libXrandr
    xorg.libXdamage
    gtk2
    libappindicator-gtk2
    qt5.qtbase
    qt5.qtsvg
    qt5.qtmultimedia
        qt5.qtdeclarative
        qt5.qtquickcontrols2
    gtk3
  ];
in qt5.mkDerivation rec {
  pname = "ipfs-desktop";
  version = "0.17.0";
  src = fetchurl {
      url = "https://github.com/ipfs-shipyard/ipfs-desktop/releases/download/v${version}/ipfs-desktop-${version}-linux-amd64.deb";
      sha256 = "d15ff5492e74260e5756a83ec419bcf858545066b4d422728b8791b19a3d82ea";
  };
  buildInputs = [dpkg which tree glibc] ++ deps;

  unpackPhase = ''
    dpkg-deb -x $src unpacked
    mkdir -p $out/bin
    mv unpacked/opt unpacked/usr/share $out/
  '';
  
  installPhase = ''
    interpreter=$(patchelf --print-interpreter $(readlink -f $(which patchelf)))
    ldpath="${lib.makeLibraryPath deps}:$out/lib"
    suffix="/opt/IPFS Desktop/ipfs-desktop"
    patchelf --set-interpreter "$interpreter" --set-rpath "$ldpath" "$out$suffix"
    ldd "$out$suffix" | grep "not found"
    ln -s "$out$suffix" "$out/bin/ipfs-desktop"
    sed -e "s!$suffix!ipfs-desktop!" -i $out/share/applications/ipfs-desktop.desktop
  '';
  
  dontStrip = true;
  dontPatchELF = true;
}
