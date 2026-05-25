{ lib
, stdenv
, fetchFromGitHub
, pkg-config
, glib
, gdk-pixbuf
, libx11
, libxscrnsaver
, flameshot
, upwork
}:

stdenv.mkDerivation rec {
  pname = "upwork-wayland";
  version = "2026-03-04";

  src = fetchFromGitHub {
    owner = "tiesselune";
    repo = "upwork-wayland";
    rev = "master";
    hash = "sha256-VqVtEriP5yl0dX76rkZybnq9e9Aba7J9YlXjlbZhquI=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ glib gdk-pixbuf libx11 libxscrnsaver ];

  installPhase = ''
    runHook preInstall

    install -Dm755 gdk-screenshotter.so $out/lib/upwork-wayland/gdk-screenshotter.so
    install -Dm755 /dev/stdin $out/bin/upwork-wayland <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [ -z "''${WAYLAND_DISPLAY:-}" ]; then
  exec ${upwork}/bin/upwork "$@"
fi

export PATH=${lib.makeBinPath [ flameshot ]}:$PATH
export UPWORK_SCREENSHOT_COMMAND="''${UPWORK_SCREENSHOT_COMMAND:-flameshot full -p}"
export XDG_SESSION_TYPE=x11
export WAYLAND_DISPLAY_REAL="$WAYLAND_DISPLAY"
unset WAYLAND_DISPLAY
export LD_PRELOAD="$out/lib/upwork-wayland/gdk-screenshotter.so''${LD_PRELOAD:+ $LD_PRELOAD}"
exec ${upwork}/bin/upwork "$@"
EOF

    runHook postInstall
  '';

  meta = {
    description = "Wrapper that lets Upwork take screenshots under GNOME Wayland";
    homepage = "https://github.com/tiesselune/upwork-wayland";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
