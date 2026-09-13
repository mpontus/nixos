{ lib, pkgs, ... }:
let
  # Shared island geometry. XMonad resolves horizontal anchors from root width.
  xfceIslands = rec {
    viewportWidth = 1920;
    outerGap = 8;
    top = outerGap; # match windows' physical screen-edge gap
    height = 36; # outer island height, including the GTK outline
    radius = 12;
    outline = 2;
    # GTK adds a 2px physical frame here; calibrated against fresh VM geometry.
    panelSize = height - outline;
    centerY = top + height / 2;
    edgeGap = outerGap;
    islandGap = 16;
    outlineColor = "#b75681";
    fill = "#0e1624";
    # One percent is the minimum; XFCE expands each panel to plugin requisition.
    left = { lengthPercent = 1; centerX = 195; };
    center = { lengthPercent = 1; centerX = viewportWidth / 2; };
    right = { lengthPercent = 1; centerX = viewportWidth - 200; };
    power = { lengthPercent = 1; centerX = viewportWidth - 30; };
    visibleWindowGap = 16;
    # spacing contributes outerGap once to the terminal's top edge.
    topGap = top + height + visibleWindowGap - outerGap;
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
  gtkAccent = pkgs.runCommandCC "gtk-accent" {
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.gtk3 ];
  } ''
    mkdir -p "$out/bin"
    cat > gtk-accent.c <<'EOF'
    #include <gtk/gtk.h>
    #include <stdio.h>

    int main(int argc, char **argv) {
      GdkRGBA color;
      gtk_init(&argc, &argv);
      GtkStyleContext *context = gtk_widget_get_style_context(gtk_button_new());
      if (!gtk_style_context_lookup_color(context, "theme_selected_bg_color", &color)) {
        gtk_style_context_set_state(context, GTK_STATE_FLAG_SELECTED);
        gtk_style_context_get_background_color(context, GTK_STATE_FLAG_SELECTED, &color);
      }
      printf("#%02x%02x%02x\n",
        (int)(color.red * 255 + 0.5),
        (int)(color.green * 255 + 0.5),
        (int)(color.blue * 255 + 0.5));
      return 0;
    }
    EOF
    $CC $(pkg-config --cflags gtk+-3.0) gtk-accent.c \
      $(pkg-config --libs gtk+-3.0) -o "$out/bin/gtk-accent"
  '';
in {
  services.xserver.desktopManager.xfce = {
    enable = true;
    noDesktop = false;
    enableXfwm = false;
  };

  services.xserver.windowManager.xmonad = {
    enable = true;
    enableContribAndExtras = true;
    config = null;
  };

  services.picom = {
    enable = true;
    package = pkgs.picom;
    backend = "glx";
    vSync = false;
    fade = true;
    fadeDelta = 50;
    fadeSteps = [ 1 1 ];
    fadeExclude = [ "class_g = 'Rofi'" ];
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
    gtkAccent
    referenceGtkTheme
    papirus-icon-theme
    kdePackages.breeze
    xfce.xfce4-panel
    xfce.xfce4-whiskermenu-plugin
    xfce.xfce4-xkb-plugin
    xfce.xfce4-pulseaudio-plugin
    snixembed
    pavucontrol
    material-icons
    font-awesome
    xfce.xfce4-terminal
  ];

  home-manager.users.mpontus.xsession.enable = true;
  # Keep Home Manager's default `setxkbmap -layout us` service from
  # overriding services.xserver.xkb after login or keyboard hotplug.
  home-manager.users.mpontus.home.keyboard = null;

  # Apply through xfconf, not its mutable XML cache.
  home-manager.users.mpontus.xfconf.settings = {
    keyboard-layout."Default/XkbDisable" = true;
    xfce4-keyboard-shortcuts."commands/custom/Print" = "flameshot gui";
    xfce4-panel."plugins/plugin-15/display-type" = {
      type = "uint";
      value = 2; # system-font layout label
    };
  };

  home-manager.users.mpontus.xdg.configFile = {
    "xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml".force = true;
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
            <property name="plugin-ids" type="array"><value type="int" value="6"/><value type="int" value="15"/><value type="int" value="8"/><value type="int" value="9"/><value type="int" value="10"/></property>
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
          <property name="plugin-15" type="string" value="xkb"/>
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
    "xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml".force = true;
    "xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xfce4-desktop" version="1.0">
        <property name="desktop-icons" type="empty">
          <property name="style" type="int" value="0"/>
        </property>
        <property name="backdrop" type="empty">
          <property name="screen0" type="empty">
            <property name="monitoreDP-1" type="empty">
              <property name="workspace0" type="empty">
                <property name="last-image" type="string" value="${pkgs.pantheon.elementary-wallpapers}/share/backgrounds/Ashim DSilva.jpg"/>
              </property>
            </property>
            <property name="monitorHDMI-1" type="empty">
              <property name="workspace0" type="empty">
                <property name="last-image" type="string" value="${pkgs.pantheon.elementary-wallpapers}/share/backgrounds/Ashim DSilva.jpg"/>
              </property>
            </property>
          </property>
        </property>
      </channel>
    '';
    "xfce4/xfconf/xfce-perchannel-xml/xsettings.xml".force = true;
    "xfce4/xfconf/xfce-perchannel-xml/xsettings.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xsettings" version="1.0">
        <property name="Net" type="empty">
          <property name="ThemeName" type="string" value="Mpontus-Reference"/>
          <property name="IconThemeName" type="string" value="Papirus-Dark"/>
        </property>
        <property name="Gtk" type="empty">
          <property name="CursorThemeName" type="string" value="breeze_cursors"/>
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
      allow_remote_control yes
      map ctrl+shift+t new_tab_with_cwd
      bell_on_tab "🔔 "
      enable_audio_bell yes
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
