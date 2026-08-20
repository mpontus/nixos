{ lib, pkgs, ... }:
let
  # Shared island geometry. XMonad resolves horizontal anchors from root width.
  xfceIslands = rec {
    viewportWidth = 1920;
    top = 23;
    height = 36; # outer island height, including the GTK outline
    radius = 9;
    outline = 2;
    # GTK adds a 2px physical frame here; calibrated against fresh VM geometry.
    panelSize = height - outline;
    centerY = top + height / 2;
    edgeGap = 12;
    islandGap = 12;
    outlineColor = "#b75681";
    fill = "#0e1624";
    # One percent is the minimum; XFCE expands each panel to plugin requisition.
    left = { lengthPercent = 1; centerX = 195; };
    center = { lengthPercent = 1; centerX = viewportWidth / 2; };
    right = { lengthPercent = 1; centerX = viewportWidth - 200; };
    power = { lengthPercent = 1; centerX = viewportWidth - 30; };
    outerGap = 6;
    visibleWindowGap = 13;
    # spacingWithEdge contributes outerGap twice to the terminal's top edge.
    topGap = top + height + visibleWindowGap - 2 * outerGap;
  };
  appmenuXfce = pkgs.stdenv.mkDerivation {
    pname = "vala-panel-appmenu-xfce";
    version = "2026-08-16";
    src = pkgs.fetchFromGitHub {
      owner = "rilian-la-te";
      repo = "vala-panel-appmenu";
      rev = "468ea01ec770378e7ce15fdb86a39972fe5064b4";
      hash = "sha256-950fojQck84qEpylVHqxbtkplHB77sGHz5BsrIsrmwU=";
    };
    nativeBuildInputs = with pkgs; [ meson ninja pkg-config vala gettext cmake gobject-introspection ];
    buildInputs = with pkgs; [
      glib gtk3 libwnck gobject-introspection xfce.xfce4-panel xfce.xfconf
    ];
    postPatch = ''
      substituteInPlace subprojects/appmenu-gtk-module/src/gtk-2.0/meson.build \
        --replace-fail "gtk2.get_variable(pkgconfig:'libdir')" "get_option('libdir')"
      substituteInPlace subprojects/appmenu-gtk-module/src/gtk-3.0/meson.build \
        --replace-fail "gtk3.get_variable(pkgconfig:'libdir')" "get_option('libdir')"
      substituteInPlace applets/meson.build \
        --replace-fail "xp.get_variable(pkgconfig:'libdir')" "get_option('libdir')"
      substituteInPlace data/meson.build \
        --replace-fail "xp.get_variable(pkgconfig:'prefix')" "get_option('prefix')"
    '';
    postFixup = ''
      mkdir -p $out/share/appmenu-schemas
      cp "$src"/subprojects/appmenu-gtk-module/data/org.appmenu.gtk-module.gschema.xml \
        $out/share/appmenu-schemas/
      ${pkgs.glib.dev}/bin/glib-compile-schemas $out/share/appmenu-schemas
    '';
    mesonFlags = [
      "-Dxfce=enabled"
      "-Dvalapanel=disabled"
      "-Dmate=disabled"
      "-Dbudgie=disabled"
      "-Djayatana=disabled"
      "-Dappmenu-gtk-module:gtk=3"
    ];
  };
  referenceGtkTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "mpontus-reference-gtk-theme";
    version = "1";
    dontUnpack = true;
    installPhase = ''
      theme=$out/share/themes/Mpontus-Reference
      mkdir -p "$theme/gtk-3.0"
      cat > "$theme/index.theme" <<'EOF'
      [Desktop Entry]
      Type=X-GNOME-Metatheme
      Name=Mpontus Reference
      Comment=VM reference palette based on Adwaita Dark
      EOF
      cat > "$theme/gtk-3.0/gtk.css" <<'EOF'
      @import url("resource:///org/gtk/libgtk/theme/Adwaita/gtk-contained-dark.css");
      @define-color theme_bg_color #0e1624;
      @define-color theme_base_color #131c2b;
      @define-color theme_fg_color #f4effa;
      @define-color theme_text_color #f4effa;
      @define-color theme_selected_bg_color #b75681;
      @define-color theme_selected_fg_color #ffffff;
      * {
        color: @theme_fg_color;
        font-family: "JetBrainsMono Nerd Font";
        font-size: 11px;
      }
      window, .background, menu, popover,
      #XfcePanelWindow, #XfcePanelWindowWrapper {
        background-color: @theme_bg_color;
        background-image: none;
        color: @theme_fg_color;
      }
      entry, textview text, treeview.view {
        background-color: @theme_base_color;
        color: @theme_text_color;
      }
      *:selected {
        background-color: @theme_selected_bg_color;
        color: @theme_selected_fg_color;
      }
      tooltip, tooltip.background {
        background-color: @theme_bg_color;
        color: @theme_fg_color;
        border: 2px solid @theme_selected_bg_color;
        border-radius: 9px;
        box-shadow: none;
        padding: 4px 7px;
      }
      EOF
      runHook postInstall
    '';
  };
  xfceIslandInset = pkgs.writeShellApplication {
    name = "xfce-island-inset";
    runtimeInputs = with pkgs; [ util-linux xdotool ];
    text = ''
      exec 9>/tmp/xfce-island-inset.lock
      flock -n 9 || exit 0
      while sleep 0.25; do
        read -r screen_width _ < <(xdotool getdisplaygeometry)
        left_third=$((screen_width / 3))
        right_third=$((screen_width * 2 / 3))
        while read -r id; do
          eval "$(xdotool getwindowgeometry --shell "$id" 2>/dev/null)" || continue
          (( WIDTH > 20 && HEIGHT > 20 )) || continue
          center=$((X + WIDTH / 2))
          if (( center < left_third )); then
            target_x=10
          elif (( center > right_third )); then
            target_x=$((screen_width - WIDTH - 10))
          else
            target_x=$(((screen_width - WIDTH) / 2))
          fi
          (( X == target_x && Y == 16 )) || xdotool windowmove "$id" "$target_x" 16
        done < <(xdotool search --name '^xfce4-panel$' 2>/dev/null)
      done
    '';
  };
  plasmaClock = pkgs.stdenvNoCC.mkDerivation {
    pname = "plasma-reference-clock";
    version = "1";
    dontUnpack = true;
    installPhase = ''
      applet=$out/share/plasma/plasmoids/org.mpontus.referenceclock
      mkdir -p "$applet/contents/ui"
      cat > "$applet/metadata.json" <<'EOF'
      { "KPlugin": { "Id": "org.mpontus.referenceclock", "Name": "Reference Clock", "Version": "1" }, "KPackageStructure": "Plasma/Applet", "X-Plasma-API": "declarativeappletscript", "X-Plasma-API-Min-Version": "6.0", "X-Plasma-MainScript": "ui/main.qml" }
      EOF
      cat > "$applet/contents/ui/main.qml" <<'EOF'
      import QtQuick
      import QtQuick.Layouts
      import org.kde.plasma.plasmoid
      PlasmoidItem {
          id: root
          property string now: ""
          function tick() { root.now = Qt.formatDateTime(new Date(), "ddd d MMM | hh:mm") }
          Component.onCompleted: tick()
          Timer { interval: 1000; running: true; repeat: true; onTriggered: root.tick() }
          preferredRepresentation: fullRepresentation
          compactRepresentation: Item {
              Layout.preferredWidth: 190; Layout.preferredHeight: 28
              implicitWidth: 190; implicitHeight: 28
              Text { anchors.centerIn: parent; text: root.now; color: "#f5f0f7"; font.family: "Noto Sans"; font.pixelSize: 11; font.weight: Font.Medium }
          }
          fullRepresentation: Item {
              Layout.preferredWidth: 190; Layout.preferredHeight: 28
              implicitWidth: 190; implicitHeight: 28
              Text { anchors.centerIn: parent; text: root.now; color: "#f5f0f7"; font.family: "Noto Sans"; font.pixelSize: 11; font.weight: Font.Medium }
          }
      }
      EOF
    '';
  };
  plasmaTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "plasma-theme-mpontus-reference";
    version = "1";
    dontUnpack = true;
    installPhase = ''
      theme=$out/share/plasma/desktoptheme/mpontus-reference
      mkdir -p "$theme"
      printf '{ "KPlugin": { "Id": "mpontus-reference", "Name": "MPontus Reference", "Version": "7" }, "X-Plasma-FallbackTheme": "default" }' > "$theme/metadata.json"
      cp ${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors "$theme/colors"
      sed -i \
        -e 's/42,46,50/14,22,36/g' \
        -e 's/49,54,59/19,28,43/g' \
        -e 's/61,174,233/240,90,157/g' \
        -e 's/239,240,241/245,240,247/g' \
        -e 's/^ColorScheme=.*/ColorScheme=MPontus Reference/' \
        -e 's/^Name=.*/Name=MPontus Reference/' \
        "$theme/colors"
      mkdir -p "$theme/widgets"
      cat > "$theme/widgets/panel-background.svg" <<'SVGEOF'
      <svg xmlns="http://www.w3.org/2000/svg" width="64" height="28" viewBox="0 0 64 28">
      <defs>
        <linearGradient id="topBorder" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8a466d"/><stop offset="1" stop-color="#d36b90"/></linearGradient>
        <linearGradient id="bottomBorder" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#cb5986"/><stop offset="1" stop-color="#5e3952"/></linearGradient>
        <linearGradient id="leftBorder" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8a466d"/><stop offset="1" stop-color="#cb5986"/></linearGradient>
        <linearGradient id="rightBorder" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#d36b90"/><stop offset="1" stop-color="#5e3952"/></linearGradient>
      </defs>
      <rect id="hint-stretch-borders" x="0" y="0" width="1" height="1" fill="none"/>
      <rect id="topleft" x="0" y="0" width="6" height="6" fill="#0e1624"/>
      <rect id="top" x="6" y="0" width="52" height="1" fill="url(#topBorder)"/>
      <rect id="topright" x="58" y="0" width="6" height="6" fill="#0e1624"/>
      <rect id="left" x="0" y="6" width="1" height="16" fill="url(#leftBorder)"/>
      <rect id="center" x="6" y="6" width="52" height="16" fill="#0e1624"/>
      <rect id="right" x="63" y="6" width="1" height="16" fill="url(#rightBorder)"/>
      <rect id="bottomleft" x="0" y="22" width="6" height="6" fill="#0e1624"/>
      <rect id="bottom" x="6" y="27" width="52" height="1" fill="url(#bottomBorder)"/>
      <rect id="bottomright" x="58" y="22" width="6" height="6" fill="#0e1624"/>
      <rect id="north-hint-stretch-borders" x="0" y="0" width="1" height="1" fill="none"/>
      <rect id="north-topleft" x="0" y="0" width="6" height="6" fill="#0e1624"/>
      <rect id="north-top" x="6" y="0" width="52" height="1" fill="url(#topBorder)"/>
      <rect id="north-topright" x="58" y="0" width="6" height="6" fill="#0e1624"/>
      <rect id="north-left" x="0" y="6" width="1" height="16" fill="url(#leftBorder)"/>
      <rect id="north-center" x="6" y="6" width="52" height="16" fill="#0e1624"/>
      <rect id="north-right" x="63" y="6" width="1" height="16" fill="url(#rightBorder)"/>
      <rect id="north-bottomleft" x="0" y="22" width="6" height="6" fill="#0e1624"/>
      <rect id="north-bottom" x="6" y="27" width="52" height="1" fill="url(#bottomBorder)"/>
      <rect id="north-bottomright" x="58" y="22" width="6" height="6" fill="#0e1624"/>
      <rect id="floating-hint-stretch-borders" x="0" y="0" width="1" height="1" fill="none"/>
      <rect id="floating-topleft" x="0" y="0" width="6" height="6" fill="#0e1624"/>
      <rect id="floating-top" x="6" y="0" width="52" height="1" fill="url(#topBorder)"/>
      <rect id="floating-topright" x="58" y="0" width="6" height="6" fill="#0e1624"/>
      <rect id="floating-left" x="0" y="6" width="1" height="16" fill="url(#leftBorder)"/>
      <rect id="floating-center" x="6" y="6" width="52" height="16" fill="#0e1624"/>
      <rect id="floating-right" x="63" y="6" width="1" height="16" fill="url(#rightBorder)"/>
      <rect id="floating-bottomleft" x="0" y="22" width="6" height="6" fill="#0e1624"/>
      <rect id="floating-bottom" x="6" y="27" width="52" height="1" fill="url(#bottomBorder)"/>
      <rect id="floating-bottomright" x="58" y="22" width="6" height="6" fill="#0e1624"/>
      <rect id="translucent-hint-stretch-borders" x="0" y="0" width="1" height="1" fill="none"/>
      <rect id="translucent-topleft" x="0" y="0" width="6" height="6" fill="#0e1624"/>
      <rect id="translucent-top" x="6" y="0" width="52" height="1" fill="url(#topBorder)"/>
      <rect id="translucent-topright" x="58" y="0" width="6" height="6" fill="#0e1624"/>
      <rect id="translucent-left" x="0" y="6" width="1" height="16" fill="url(#leftBorder)"/>
      <rect id="translucent-center" x="6" y="6" width="52" height="16" fill="#0e1624"/>
      <rect id="translucent-right" x="63" y="6" width="1" height="16" fill="url(#rightBorder)"/>
      <rect id="translucent-bottomleft" x="0" y="22" width="6" height="6" fill="#0e1624"/>
      <rect id="translucent-bottom" x="6" y="27" width="52" height="1" fill="url(#bottomBorder)"/>
      <rect id="translucent-bottomright" x="58" y="22" width="6" height="6" fill="#0e1624"/>
      <path id="mask-topleft" d="M0,6 H6 V0 C2,0 0,2 0,6 Z" fill="#000000"/>
      <rect id="mask-top" x="6" y="0" width="52" height="6" fill="#000000"/>
      <path id="mask-topright" d="M6,6 H0 V0 C4,0 6,2 6,6 Z" transform="translate(58,0)" fill="#000000"/>
      <rect id="mask-left" x="0" y="6" width="6" height="16" fill="#000000"/>
      <rect id="mask-center" x="6" y="6" width="52" height="16" fill="#000000"/>
      <rect id="mask-right" x="58" y="6" width="6" height="16" fill="#000000"/>
      <path id="mask-bottomleft" d="M0,0 H6 V6 C2,6 0,4 0,0 Z" transform="translate(0,22)" fill="#000000"/>
      <rect id="mask-bottom" x="6" y="22" width="52" height="6" fill="#000000"/>
      <path id="mask-bottomright" d="M6,0 H0 V6 C4,6 6,4 6,0 Z" transform="translate(58,22)" fill="#000000"/>
      </svg>
SVGEOF
    '';
  };
  plasmaIslands = pkgs.writeShellScript "plasma-islands" ''
    set -eu
    evaluate() {
      /run/current-system/sw/bin/qdbus org.kde.plasmashell \
        /PlasmaShell org.kde.PlasmaShell.evaluateScript "$1"
    }
    for attempt in $(seq 1 60); do
      [ "$(evaluate 'print(panels().length)' 2>/dev/null || true)" -ge 1 ] && break
      sleep 1
    done
    evaluate '
      for (const desktop of desktops()) {
        desktop.wallpaperPlugin = "org.kde.color";
        desktop.currentConfigGroup = Array("Wallpaper", "org.kde.color", "General");
        desktop.writeConfig("Color", "#131c2b");
      }
      for (const panel of panels()) panel.remove();
    '
    evaluate '
      const left = new Panel;
      left.location = "top";
      left.alignment = "left";
      left.lengthMode = "fit";
      left.height = 28;
      left.hiding = "none";
      left.addWidget("org.kde.plasma.kickoff");
      left.addWidget("org.kde.plasma.appmenu");
      const center = new Panel;
      center.location = "top";
      center.alignment = "center";
      center.lengthMode = "fit";
      center.height = 28;
      center.addWidget("org.mpontus.referenceclock");
      const right = new Panel;
      right.location = "top";
      right.alignment = "right";
      right.lengthMode = "fit";
      right.height = 28;
      right.addWidget("org.kde.plasma.systemtray");
    '
    /run/current-system/sw/bin/plasma-apply-desktoptheme mpontus-reference || true
    /run/current-system/sw/bin/plasma-apply-colorscheme BreezeDark || true
    # Top panels anchor at y=0. Move whole dock windows below reference gap;
    # Picom GLX then rounds visible surface rather than transparent padding.
    export DISPLAY=:0 XAUTHORITY="$HOME/.Xauthority"
    sleep 1
    for id in $(/run/current-system/sw/bin/xdotool search --class plasmashell 2>/dev/null || true); do
      /run/current-system/sw/bin/xprop -id "$id" _NET_WM_WINDOW_TYPE 2>/dev/null | grep -q '_NET_WM_WINDOW_TYPE_DOCK' || continue
      x=
      for pair in $(/run/current-system/sw/bin/xdotool getwindowgeometry --shell "$id"); do
        case "$pair" in X=*) x=''${pair#X=} ;; esac
      done
      [ -n "$x" ] && /run/current-system/sw/bin/xdotool windowmove "$id" "$x" 16
    done
    [ "$(evaluate 'print(panels().length)')" = 3 ]
  '';
  plasmaXmonad = pkgs.writers.writeHaskellBin "plasma-xmonad" {
    ghc = pkgs.haskellPackages.ghc;
    libraries = with pkgs.haskellPackages; [ xmonad xmonad-contrib ];
  } ''
    import XMonad
    import XMonad.Hooks.EwmhDesktops
    import XMonad.Hooks.ManageDocks
    import XMonad.Hooks.SetWMName
    import XMonad.Layout.Spacing
    import XMonad.Util.EZConfig
    myConfig = ewmhFullscreen $ ewmh $ docks def
      { terminal = "${pkgs.kitty}/bin/kitty"
      , modMask = mod4Mask
      , borderWidth = 1
      , normalBorderColor = "#8b5cf6"
      , focusedBorderColor = "#f25aa6"
      , layoutHook = avoidStruts $ spacingWithEdge 10 $ layoutHook def
      , manageHook = manageDocks <+> manageHook def
      , startupHook = setWMName "LG3D"
      }
      `additionalKeysP`
      [ ("M-<Return>", spawn "${pkgs.kitty}/bin/kitty")
      , ("M-d", spawn "qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu")
      , ("M-S-e", spawn "qdbus org.kde.ksmserver /KSMServer org.kde.KSMServerInterface.logout -1 -1 -1")
      ]
    main :: IO ()
    main = getDirectories >>= launch myConfig
  '';
in {
  services.xserver.desktopManager.xfce = {
    enable = true;
    noDesktop = true;
    enableXfwm = false;
  };

  services.xserver.windowManager.xmonad = {
    enable = true;
    enableContribAndExtras = true;
    extraPackages = hp: [ hp.xmonad hp.xmonad-contrib hp.xmonad-extras ];
    config = ''
      import Control.Monad (when)
      import Data.Monoid (All (..))
      import Graphics.X11.Xlib (defaultRootWindow, getGeometry, moveWindow, setWindowBorder, setWindowBorderWidth)
      import XMonad
      import XMonad.Config.Xfce
      import XMonad.Hooks.EwmhDesktops
      import XMonad.Hooks.ManageDocks
      import XMonad.Hooks.ManageHelpers (isInProperty)
      import XMonad.Hooks.SetWMName
      import XMonad.Layout.Gaps
      import XMonad.Layout.Spacing
      import XMonad.Util.EZConfig
      import XMonad.Util.NamedActions

      nativePanelBorder :: ManageHook
      nativePanelBorder = do
        window <- ask
        liftX $ withDisplay $ \display -> io $ do
          setWindowBorder display window 0xffb75681
          setWindowBorderWidth display window ${toString xfceIslands.outline}
        idHook
      anchorPanels :: Event -> X All
      anchorPanels ConfigureEvent
        { ev_window = window
        , ev_x = x
        , ev_y = y
        , ev_width = width
        , ev_height = height
        } = do
          panelClass <- runQuery className window
          when (panelClass == "Xfce4-panel" && height == ${toString xfceIslands.height}) $
            withDisplay $ \display -> io $ do
              (_, _, _, rootWidth, _, _, _) <- getGeometry display (defaultRootWindow display)
              let border = ${toString xfceIslands.outline}
                  width' = fromIntegral width :: Int
                  x' = fromIntegral x :: Int
                  outerWidth = width' + 2 * border
                  center = x' + width' `div` 2
                  edge = ${toString xfceIslands.edgeGap}
                  gap = ${toString xfceIslands.islandGap}
                  screenWidth = fromIntegral rootWidth :: Int
                  powerOuterWidth = 40
                  powerLeft = screenWidth - edge - powerOuterWidth
                  targetX
                    | width' < 60 = screenWidth - edge - outerWidth
                    | center < screenWidth `div` 3 = edge
                    | center < 2 * screenWidth `div` 3 = (screenWidth - outerWidth) `div` 2
                    | otherwise = powerLeft - gap - outerWidth
                  targetY = ${toString xfceIslands.top}
              when (x' /= targetX || fromIntegral y /= targetY) $
                moveWindow display window (fromIntegral targetX) (fromIntegral targetY)
          pure (All True)
      anchorPanels _ = pure (All True)
      myKeys c = (subtitle "Custom Keys" :) $ mkNamedKeymap c
        [ ("M-<Return>", addName "Open Kitty" $ spawn "${pkgs.kitty}/bin/kitty")
        , ("M-d", addName "Open Whisker menu" $ spawn "xfce4-popup-whiskermenu")
        , ("M-f", addName "Toggle focused-window fullscreen" $ spawn "${pkgs.wmctrl}/bin/wmctrl -r :ACTIVE: -b toggle,fullscreen")
        , ("M-S-e", addName "Log out" $ spawn "xfce4-session-logout")
        ]
      main :: IO ()
      main = getDirectories >>= launch (ewmhFullscreen $ ewmh $ docks $ addDescrKeys ((mod4Mask, xK_F1), xMessage) myKeys $ xfceConfig
        { terminal = "${pkgs.kitty}/bin/kitty"
        , modMask = mod4Mask
        , borderWidth = ${toString xfceIslands.outline}
        , normalBorderColor = "${xfceIslands.outlineColor}"
        , focusedBorderColor = "${xfceIslands.outlineColor}"
        , layoutHook = avoidStruts $ gaps [(U, ${toString xfceIslands.topGap})] $ spacingWithEdge ${toString xfceIslands.outerGap} $ layoutHook xfceConfig
        , handleEventHook = anchorPanels <+> handleEventHook xfceConfig
        , manageHook =
            ((className =? "Xfce4-panel") --> nativePanelBorder)
            <+> ((className =? "Wrapper-2.0" <&&>
                  isInProperty "_NET_WM_WINDOW_TYPE" "_NET_WM_WINDOW_TYPE_MENU") --> doIgnore)
            <+> manageDocks <+> manageHook xfceConfig
        , startupHook = do
            startupHook xfceConfig
            spawn "hsetroot -solid '#131c2b'"
            spawn "snixembed"
            spawn "nm-applet"
            spawn "xfce4-power-manager"
            setWMName "LG3D"
        })
    '';
  };

  environment.etc."polybar-xmonad/config.ini".text = ''
    [colors]
    bg = #cc0f172a
    bg-alt = #cc1e293b
    fg = #e5e7eb
    muted = #94a3b8
    accent = #b4befe
    warm = #f5c2e7

    [bar/base]
    monitor =
    fixed-center = true
    override-redirect = false
    wm-restack = generic
    bottom = false
    height = 30
    radius = 14
    background = ''${colors.bg}
    foreground = ''${colors.fg}
    border-size = 2
    border-color = #3b5274
    padding-left = 4
    padding-right = 4
    module-margin = 3
    font-0 = JetBrainsMono Nerd Font:size=10;2
    font-1 = Symbols Nerd Font:size=11;2

    [bar/workspaces]
    inherit = bar/base
    width = 28%
    offset-x = 20
    offset-y = 8
    modules-center = xworkspaces

    [bar/clock]
    inherit = bar/base
    width = 24%
    offset-x = 38%
    offset-y = 8
    modules-center = date

    [bar/tray]
    inherit = bar/base
    width = 26%
    offset-x = 72%
    offset-y = 8
    modules-center = network tray

    [module/xworkspaces]
    type = internal/xworkspaces
    group-by-monitor = false
    format = <label-state>
    label-active = %name%
    label-active-foreground = #ff111827
    label-active-background = #ffb4befe
    label-active-padding = 2
    label-occupied = %name%
    label-occupied-foreground = #ffe5e7eb
    label-occupied-padding = 2
    label-empty = %name%
    label-empty-foreground = #ffe5e7eb
    label-empty-padding = 2

    [module/network]
    type = internal/network
    interface = eth0
    interval = 5
    format-connected = <label-connected>
    label-connected = 󰈀 wired
    format-disconnected = <label-disconnected>
    label-disconnected = 󰤭 off
    label-disconnected-foreground = ''${colors.warm}
    click-left = nm-connection-editor

    [module/date]
    type = internal/date
    interval = 1
    date = %a %d %b
    time = %I:%M %p
    label = %date% | %time%

    [module/tray]
    type = internal/tray
    format-margin = 1
    tray-spacing = 8px
    tray-size = 70%
  '';

  environment.etc."rofi-xmonad/theme.rasi".text = ''
    configuration {
      show-icons: true;
      icon-theme: "Papirus-Dark";
      drun-display-format: "{name}";
      font: "Noto Sans 11";
    }

    * {
      bg: #0f172aee;
      bg-alt: #1e293bee;
      fg: #e5e7eb;
      muted: #93a4c7;
      accent: #b4befe;
      border: #3b5274;
    }

    window {
      width: 58%;
      location: center;
      anchor: center;
      border: 2px;
      border-color: @border;
      border-radius: 14px;
      background-color: @bg;
      padding: 14px;
    }

    mainbox {
      spacing: 12px;
      background-color: transparent;
    }

    inputbar {
      children: [entry];
      background-color: @bg-alt;
      border-radius: 12px;
      padding: 10px 12px;
      spacing: 8px;
    }

    prompt {
      text-color: @accent;
      background-color: transparent;
    }
    entry {
      text-color: @fg;
      placeholder: "Search apps";
      background-color: transparent;
    }

    listview {
      columns: 2;
      lines: 6;
      spacing: 6px;
      fixed-height: true;
      background-color: transparent;
    }

    element {
      children: [element-icon, element-text];
      padding: 9px 10px;
      border-radius: 10px;
      background-color: transparent;
      text-color: @fg;
    }

    element selected {
      background-color: @accent;
      text-color: #111827;
    }

    element-icon {
      size: 24px;
      margin: 0 10px 0 0;
      background-color: transparent;
    }
    element-text {
      vertical-align: 0.5;
      background-color: transparent;
      text-color: inherit;
    }

    scrollbar { handle-color: @accent; background-color: transparent; }
  '';

  services.picom = {
    enable = true;
    package = pkgs.picom;
    backend = "glx";
    vSync = false;
    fade = false;
    shadow = false;
    settings = {
      corner-radius = xfceIslands.radius;
      corner-radius-rules = [ "${toString xfceIslands.radius}:window_type = 'dock'" ];
      use-damage = false;
      rounded-corners-exclude = [ "window_type = 'desktop'" ];
    };
  };

  # XFCE owns native panel geometry; no Plasma shell or panel provisioning.
  environment.sessionVariables = {
    GTK_MODULES = "appmenu-gtk-module";
    GTK_PATH = "${appmenuXfce}/lib";
    GSETTINGS_SCHEMA_DIR = "${appmenuXfce}/share/appmenu-schemas";
    UBUNTU_MENUPROXY = "1";
  };
  environment.systemPackages = with pkgs; [
    appmenuXfce
    referenceGtkTheme
    papirus-icon-theme
    xdotool
    xorg.xwininfo
    xorg.xprop
    xfce.xfce4-panel
    xfce.xfce4-whiskermenu-plugin
    xfce.xfce4-pulseaudio-plugin
    dmenu
    i3status
    st
    polybar
    rofi
    snixembed
    pavucontrol
    hsetroot
    papirus-icon-theme
    feh
    material-icons
    font-awesome
    xorg.xsetroot
    xfce.xfce4-terminal
    unstable.upwork
    (callPackage ./pkgs/upwork-wayland { upwork = unstable.upwork; })
    (callPackage ./pkgs/toptracker { })
  ];

  home-manager.users.mpontus.xdg.configFile = {
    "xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xfce4-panel" version="1.0">
        <property name="configver" type="int" value="2"/>
        <property name="panels" type="array">
          <value type="int" value="1"/><value type="int" value="2"/><value type="int" value="3"/><value type="int" value="4"/>
          <property name="dark-mode" type="bool" value="true"/>
          <property name="panel-1" type="empty">
            <property name="position" type="string" value="p=0;x=${toString xfceIslands.left.centerX};y=${toString xfceIslands.centerY}"/>
            <property name="length" type="double" value="${toString xfceIslands.left.lengthPercent}"/><property name="length-adjust" type="bool" value="true"/><property name="size" type="uint" value="${toString xfceIslands.panelSize}"/>
            <property name="position-locked" type="bool" value="true"/><property name="enable-struts" type="bool" value="false"/>
            <property name="plugin-ids" type="array"><value type="int" value="1"/><value type="int" value="7"/></property>
          </property>
          <property name="panel-2" type="empty">
            <property name="position" type="string" value="p=0;x=${toString xfceIslands.center.centerX};y=${toString xfceIslands.centerY}"/>
            <property name="length" type="double" value="${toString xfceIslands.center.lengthPercent}"/><property name="length-adjust" type="bool" value="true"/><property name="size" type="uint" value="${toString xfceIslands.panelSize}"/>
            <property name="position-locked" type="bool" value="true"/><property name="enable-struts" type="bool" value="false"/>
            <property name="plugin-ids" type="array"><value type="int" value="12"/></property>
          </property>
          <property name="panel-3" type="empty">
            <property name="position" type="string" value="p=0;x=${toString xfceIslands.right.centerX};y=${toString xfceIslands.centerY}"/>
            <property name="length" type="double" value="${toString xfceIslands.right.lengthPercent}"/><property name="length-adjust" type="bool" value="true"/><property name="size" type="uint" value="${toString xfceIslands.panelSize}"/>
            <property name="position-locked" type="bool" value="true"/><property name="enable-struts" type="bool" value="false"/>
            <property name="plugin-ids" type="array"><value type="int" value="6"/><value type="int" value="8"/><value type="int" value="9"/><value type="int" value="10"/></property>
          </property>
          <property name="panel-4" type="empty">
            <property name="position" type="string" value="p=0;x=${toString xfceIslands.power.centerX};y=${toString xfceIslands.centerY}"/>
            <property name="length" type="double" value="${toString xfceIslands.power.lengthPercent}"/><property name="length-adjust" type="bool" value="true"/><property name="size" type="uint" value="${toString xfceIslands.panelSize}"/>
            <property name="position-locked" type="bool" value="true"/><property name="enable-struts" type="bool" value="false"/>
            <property name="plugin-ids" type="array"><value type="int" value="14"/></property>
          </property>
        </property>
        <property name="plugins" type="empty">
          <property name="plugin-1" type="string" value="whiskermenu">
            <property name="menu-width" type="int" value="360"/>
            <property name="menu-height" type="int" value="400"/>
            <property name="launcher-show-description" type="bool" value="false"/>
          </property>
          <property name="plugin-6" type="string" value="systray"><property name="square-icons" type="bool" value="true"/></property>
          <property name="plugin-7" type="string" value="appmenu"/>
          <property name="plugin-8" type="string" value="pulseaudio"/>
          <property name="plugin-9" type="string" value="power-manager-plugin"/>
          <property name="plugin-10" type="string" value="notification-plugin"/>
          <property name="plugin-12" type="string" value="clock">
            <property name="mode" type="uint" value="2"/>
            <property name="digital-layout" type="uint" value="2"/>
            <property name="digital-date-format" type="string" value="%a %d %b  |  %I:%M %p"/>
          </property>
          <property name="plugin-14" type="string" value="actions">
            <property name="appearance" type="uint" value="0"/>
            <property name="items" type="array"><value type="string" value="+logout"/></property>
          </property>
        </property>
      </channel>
    '';
    "xfce4/xfconf/xfce-perchannel-xml/xsettings.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xsettings" version="1.0">
        <property name="Net" type="empty">
          <property name="ThemeName" type="string" value="Mpontus-Reference"/>
          <property name="IconThemeName" type="string" value="Papirus-Dark"/>
        </property>
      </channel>
    '';
    "gtk-3.0/gtk.css".text = ''
      #XfcePanelWindow {
        border: 0;
        border-radius: ${toString xfceIslands.radius}px;
        box-shadow: none;
        margin: 0;
        padding: 0;
      }
      #clock-button {
        padding-left: 16px;
        padding-right: 16px;
      }
      #whiskermenu-button, #sn-button, #pulseaudio-button,
      #xfce4-power-manager-plugin, #xfce4-notification-plugin, #actions-button {
        padding: 2px 4px;
      }
      #actions-button {
        padding-left: 16px;
        padding-right: 16px;
      }
      .-vala-panel-appmenu-private > menuitem {
        padding: 2px 3px;
      }
      menubar.-vala-panel-appmenu-private {
        padding-right: 8px;
      }
    '';
    "kitty/kitty.conf".text = ''
      background #131c2b
      foreground #f4effa
    '';
    "xfce4/terminal/terminalrc".text = ''
      [Configuration]
      ColorBackground=#131c2b
      ColorForeground=#f4effa
      FontName=JetBrainsMono Nerd Font 11
      MiscMenubarDefault=TRUE
      MiscToolbarDefault=FALSE
      MiscBordersDefault=FALSE
      ScrollingBar=TERMINAL_SCROLLBAR_NONE
    '';
  };
  networking.networkmanager.enable = true;
  programs.nm-applet.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  services.displayManager.defaultSession = lib.mkForce "xfce+xmonad";
}
