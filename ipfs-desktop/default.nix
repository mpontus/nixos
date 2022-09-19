# -*- compile-command: "nix-build"; eval: (add-hook 'after-save-hook 'recompile nil t); -*-
{ pkgs ? import <nixpkgs> {} }:
pkgs.appimageTools.wrapType2 {
  name = "IPFS-Desktop";
  src = pkgs.fetchurl {
    url = "https://github.com/ipfs-shipyard/ipfs-desktop/releases/download/v0.17.0/ipfs-desktop-0.17.0-linux-x86_64.AppImage";
    sha256 = "c8c696f33605cf4acba5ce1302db2d812822fbf5eb3ab7fbbd6dc0b3cfea743f";
  };
}
