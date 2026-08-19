# edit this configuration file to define what should be installed on
# your system.  help is available in the configuration.nix(5) man page
# and in the nixos manual (accessible by running ‘nixos-help’).
{ config, lib,  pkgs, inputs, ... }:

{
  imports =
    [ # include the results of the hardware scan.
      ./hardware-configuration.nix
      # ./pia-openvpn.nix
      # ./cachix.nix
      
    ];

  environment.systemPackages = with pkgs; [
    pkgs.virt-manager
    (pkgs.writeShellScriptBin "nixos-vm" ''
      exec systemd-inhibit \
        --what=sleep:handle-lid-switch \
        --mode=block \
        --who="nixos-vm" \
        --why="QEMU VM running" \
        "$@"
    '')
    gnome-tweaks
    gnomeExtensions.appindicator
    dmenu
    st
    ly
    unstable.uv
    pkg-config libssh2 zlib
    unstable.postman
    git
    gnumake gcc binutils cmake
    openssl
  ];

  nixpkgs.overlays = [
    (let
      moz-rev = "16ab32eeb8390de633eb336eb4910efbbe0091e6";
      moz-url = builtins.fetchTarball { url = "https://github.com/mozilla/nixpkgs-mozilla/archive/${moz-rev}.tar.gz";
                                        sha256 = "0j7b6wdzs6v65rx53zsyw7nhgc7sg7rljnijkbyyba0qva8qawar"; };
      nightlyOverlay = (import "${moz-url}/firefox-overlay.nix");
    in nightlyOverlay)
    (import (builtins.fetchTarball
    {
      url =     "https://github.com/mozilla/nixpkgs-mozilla/archive/16ab32eeb8390de633eb336eb4910efbbe0091e6.tar.gz";
      sha256 = "0j7b6wdzs6v65rx53zsyw7nhgc7sg7rljnijkbyyba0qva8qawar";
    }))
    (self: super: {
      yarn = super.unstable.yarn.overrideAttrs (oldAttrs: {
        version = "1.22.19";
        src = super.fetchurl {
          url = "https://github.com/yarnpkg/yarn/releases/download/v1.22.19/yarn-v1.22.19.tar.gz";
          hash = "sha256-cyYgusixaQ1QcnTwJfPGz9w2J6hNlkLjigdFLMAODy4=";
          # sha256 = "1mfzm3k6kpfy45kzmijg9vsrck8y14jjb6rrhba6gaifa4slzdl7";
        };
      });
    })
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    unstable = import inputs.nixpkgs-unstable {
      system = "x86_64-linux";
      config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
        "corefonts"
        "upwork"
        "slack"
        "discord"
        "amazon-q-cli"
        "claude-code"
        "code" "vscode"
        "cursor"
        "postman"
        "ngrok"
        "Oracle_VirtualBox_Extension_Pack" "virtualbox-extpack"
        "steam" "steam-unwrapped"
        "spotify" "spotify-unwrapped"
      ];
    };
  };

  nixpkgs.config.permittedInsecurePackages = [
    "nodejs-16.20.2"
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "corefonts"
    "upwork"
    "slack"
    "discord"
    "amazon-q-cli"
    "claude-code"
    "code" "vscode"
    "cursor"
    "postman"
    "ngrok"
    "Oracle_VirtualBox_Extension_Pack" "virtualbox-extpack"
    "steam" "steam-unwrapped"
    "spotify" "spotify-unwrapped"
  ];




  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" ];
    allowed-users = [ "mpontus" "er" ];
    sandbox = true;
    sandbox-fallback = false;
    require-sigs = true;
    substituters = [ "https://cache.nixos.org/" ];
  };
  home-manager.users.mpontus = { pkgs, ... }: {
    imports = [
      
    ];
  
    home.packages = with pkgs; [
      dconf-editor
      pavucontrol
      input-leap
      # latest.firefox-nightly-bin
      unstable.tor-browser
      unstable.chromium
      libreoffice-qt
      hunspell
      hunspellDicts.uk_UA
      hunspellDicts.th_TH
      kdePackages.okular
      audacity
      pass
      sops
      age
      monero-gui
      tilix
      ghostty
      kitty
      wezterm
      guake
      unstable.upwork
      (callPackage ./pkgs/upwork-wayland { upwork = unstable.upwork; })
      (callPackage ./pkgs/toptracker { })
      unstable.slack
      unstable.telegram-desktop
      discord
      beep
      htop
      lsof
      inetutils
      file
      tree
      ncdu
      unzip
      sshfs
      unstable.rclone
      silver-searcher
      ripgrep
      fd
      jq
      qsv
      imagemagick
      wl-clipboard
      xclip
      wmctrl xdotool xorg.xprop xorg.xwininfo
      # unstable.nodejs
      yarn
      pnpm
      # (callPackage ./pkgs/amazon-q-cli { })
      unstable.amazon-q-cli
      unstable.opencode
      unstable.gemini-cli
      unstable.claude-code
      (unstable.callPackage ./pkgs/pi-coding-agent-latest { })
      unstable.rustc cargo wasm-pack
      unstable.gh hub
      deno
      mitmproxy
      docker-compose
      protobuf
      unstable.temporal-cli
      unstable.ngrok
      awscli2
      dbeaver-bin
      (pkgs.appimageTools.wrapType2 {
        pname = "nosql-workbench";
        version = "3.3.0";
        src = pkgs.fetchurl {
          url =
            "https://s3.amazonaws.com/nosql-workbench/NoSQL%20Workbench-linux-x86_64-3.3.0.AppImage";
          hash = "sha256-15C4R1gUEQjkENdlEep6l88+QcCx8LYHM2bBKpoPcig=";
        };
      })
      altair
      unstable.prettier
      nixfmt
      pandoc
      unstable.devenv
      spotify
      deluge
      vlc
      unstable.kodi
      obs-studio
      calibre
      spotify
    ];
  
  
    dconf.settings = {
      "ca/desrt/dconf-editor" = { show-warning = false; };
      "org/gnome/shell" = {
        enabled-extensions = [
          "places-menu@gnome-shell-extensions.gcampax.github.com"
          "native-window-placement@gnome-shell-extensions.gcampax.github.com"
          "status-icons@gnome-shell-extensions.gcampax.github.com"
          "appindicatorsupport@rgcjonas.gmail.com"
        ];
        disabled-extensions = [
          "system-monitor@gnome-shell-extensions.gcampax.github.com"
        ];
      };
    } // (lib.trivial.pipe {
      "<Super>e" = {
        name = "Switch to Emacs";
        command = "launch-or-raise -W Emacs emacs";
      };
      "<Super>i" = {
        name = "Emacs Everyhere";
        command = "emacsclient --eval '(emacs-everywhere)'";
      };
      "<Super>w" = {
        name = "Switch to Firefox";
        command = "launch-or-raise -W Navigator firefox";
      };
      "<Shift><Super>c" = {
        name = "Switch to Chromium";
        command = "launch-or-raise -W Chroimum chromium-browser";
      };
      "<Super>c" = {
        name = "Tilix";
        command = "launch-or-raise -W tilix tilix";
      };
      "<Super>\\" = {
        name = "Tilix (dropdown)";
        command = "tilix --quake";
      };
      "<Shift><Super>t" = {
        name = "Switch to TopTracker";
        command = "launch-or-raise -W TopTracker TopTracker";
      };
      "<Super>s" = {
        name = "Switch to Slack";
        command = "launch-or-raise -W Slack slack";
      };
      "<Super>t" = {
        name = "Switch to Telegram";
        command = "launch-or-raise -W TelegramDesktop telegram-desktop";
      };
      "<Super>v" = {
        name = "Switch to VSCode";
        command = "launch-or-raise -W Code code";
      };
    } [
      (lib.attrsets.mapAttrsToList (binding: { name, command }: {
        inherit binding name command;
      }))
      (lib.lists.imap0 (i: value: {
        name = "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${toString(i)}";
        inherit value;
      }))
      lib.attrsets.listToAttrs
    ]
    );
    programs.emacs = {
      enable = true;
      # package = pkgs.emacs.withPackages (epkgs: with epkgs; [
      #   vterm
      # ]);
      # package = (pkgs.emacsGit.override {
      #   withXwidgets = true;
      # });
    };
    programs.firefox.enable = true;
    # programs.firefox.package = pkgs.unstable.firefox-unwrapped;
    programs.firefox.package = pkgs.firefox-beta.unwrapped;
    # programs.firefox.package = pkgs.latest.firefox-nightly-bin.unwrapped;
    programs.bash = {
      enable = true
      ;
      historySize = 1000000000;
      historyFileSize = 1000000000;
      historyControl = ["ignoredups" "erasedups"];
      initExtra = ''
          export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
      '';
      enableVteIntegration = true;
    };
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    programs.vscode = {
      enable = false;
      package = pkgs.unstable.vscode;
      # package = pkgs.vscode-insiders;
      # extensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace (import ./vscode-extensions.nix).extensions;
    };
    programs.git = {
      enable = true;
      extraConfig = {
        user.name = "Michael Pontus";
        user.email = "m.pontus@gmail.com";
        rerere.enabled = false;
      };
    };
  
    home.stateVersion = "18.09";
  };
  home-manager.useGlobalPkgs = true;
  home-manager.users.er = { pkgs, ... }: {
    imports = [
      
    ];
  
    home.packages = with pkgs; [];
  
    home.stateVersion = "18.09";
  };
  home-manager.users.root = { pkgs, ... }: {
    home.packages = with pkgs; [ htop git ];
    home.stateVersion = "18.09";
  };
  nix.package = pkgs.nixVersions.git;
  sops.defaultSopsFile = ./secrets/ynab.yaml;
  sops.age.keyFile = "/home/mpontus/.config/sops/age/keys.txt";
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [
    "kvm-intel" "kvm-amd"
    "pcspkr"
  ];
  boot.supportedFilesystems = [ "ntfs" ];
  users.users.mpontus = {
    isNormalUser = true;
    hashedPassword = "$6$QrKXg5g6nEHsWbkm$GdlWBtzXoQo7djWCJcMYcAZ/Zypk13Bq6nETchLc49hstumtoZ2q0tKvvrX3CLxqEmnZhDA8/0aw/Sen9mo5L/";
    extraGroups = [ "wheel" "pcspkr" "input" ];
  };
  security.sudo.extraConfig = ''
    Defaults        env_reset,timestamp_timeout=30
  '';
  users.users.er = {
    isNormalUser = true;
    hashedPassword = "$6$QrKXg5g6nEHsWbkm$GdlWBtzXoQo7djWCJcMYcAZ/Zypk13Bq6nETchLc49hstumtoZ2q0tKvvrX3CLxqEmnZhDA8/0aw/Sen9mo5L/";
    extraGroups = [ "wheel" "pcspkr" "input" ];
  };
  environment.homeBinInPath = true;
  environment.sessionVariables = rec {
    XDG_CACHE_HOME  = "\${HOME}/.cache";
    XDG_CONFIG_HOME = "\${HOME}/.config";
    XDG_BIN_HOME    = "\${HOME}/.local/bin";
    XDG_DATA_HOME   = "\${HOME}/.local/share";
  
    PATH = [
      "\${XDG_BIN_HOME}"
    ];
  };
  networking.hostName = "nixos"; # Define your hostname.
  networking.enableIPv6  = false;
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;
  
  services.openvpn.servers.pia = {
    config = "config ${pkgs.fetchzip {
      url = "https://www.privateinternetaccess.com/openvpn/openvpn.zip";
      sha256 = "sha256-ZA8RS6eIjMVQfBt+9hYyhaq8LByy5oJaO9Ed+x8KtW8=";
      stripRoot = false   ;
    }}/netherlands.ovpn";
  };
  services.openvpn.servers.pia.autoStart = false;
  networking.resolvconf.dnsExtensionMechanism = false;
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = null; # Allows all users by default. Can be [ "user1" "user2" ]
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "prohibit-password"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
    };
  };
  virtualisation.libvirtd.enable = true;
  environment.variables = {
      QEMU_OPTS = "-m 4096 -smp 4 -enable-kvm";
  };
  fonts = {
    enableDefaultFonts = false;
    fonts = with pkgs; [
      corefonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      twitter-color-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      # mplus-outline-fonts
      dina-font
      proggyfonts
      source-code-pro
      gentium
    ] ++ (if pkgs ? nerd-fonts then [
      pkgs.nerd-fonts.fira-code
      pkgs.nerd-fonts.droid-sans-mono
      pkgs.nerd-fonts.jetbrains-mono
      pkgs.nerd-fonts.symbols-only
    ] else [
      (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" "JetBrainsMono" ]; })
    ]);
  };
  services.xserver.enable = true;
  services.xserver.config = ''
  Section "Device"
  
  Identifier "Intel Graphics"
  Driver "intel"
  Option "AccelMethod" "sna"
  Option "TearFree" "true"
  
  EndSection
  '';
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.settings.daemon.WaylandEnable = lib.mkForce false;
  services.xserver.desktopManager.gnome.enable = true;
  services.displayManager.defaultSession = "gnome";
  systemd.services."getty@tty1".enable = true;
  systemd.services."autovt@tty1".enable = true;
  services.xserver.displayManager.autoLogin.enable = false;
  services.xserver.displayManager.autoLogin.user = "mpontus";
  services.xserver.windowManager.dwm.enable = true;
  virtualisation.vmVariant = { lib, pkgs, ... }:
  let
    # VM-only 1024×768 island geometry. XFCE CSS and Picom consume this block.
    xfceIslands = rec {
      viewportWidth = 1024;
      top = 23;
      height = 36; # outer island height, including the GTK outline
      radius = 9;
      outline = 2;
      # GTK adds a 2px physical frame here; calibrated against fresh VM geometry.
      panelSize = height - outline;
      centerY = top + height / 2;
      outlineColor = "#b75681";
      fill = "#0e1624";
      left = { lengthPercent = 36; centerX = 195; };
      center = { lengthPercent = 19; centerX = viewportWidth / 2; };
      right = { lengthPercent = 14; centerX = 823; };
      power = { lengthPercent = 4; centerX = 990; };
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
    virtualisation.diskSize = 8192;
    # VM-only VirGL path: Picom GLX supplies real rounded corners.
    virtualisation.qemu.options = [
      "-vga none"
      "-device virtio-vga-gl"
      "-display gtk,gl=on"
    ];
  
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
        import XMonad
        import XMonad.Config.Xfce
        import XMonad.Hooks.EwmhDesktops
        import XMonad.Hooks.ManageDocks
        import XMonad.Hooks.ManageHelpers (isInProperty)
        import XMonad.Hooks.SetWMName
        import XMonad.Layout.Gaps
        import XMonad.Layout.Spacing
        import XMonad.Util.EZConfig
  
        main :: IO ()
        main = xmonad $ ewmhFullscreen $ ewmh $ docks $ xfceConfig
          { terminal = "${pkgs.kitty}/bin/kitty"
          , modMask = mod4Mask
          , borderWidth = ${toString xfceIslands.outline}
          , normalBorderColor = "${xfceIslands.outlineColor}"
          , focusedBorderColor = "${xfceIslands.outlineColor}"
          , layoutHook = avoidStruts $ gaps [(U, ${toString xfceIslands.topGap})] $ spacingWithEdge ${toString xfceIslands.outerGap} $ layoutHook xfceConfig
          , manageHook =
              (className =? "Wrapper-2.0" <&&>
               isInProperty "_NET_WM_WINDOW_TYPE" "_NET_WM_WINDOW_TYPE_MENU") --> doIgnore
              <+> manageDocks <+> manageHook xfceConfig
          , startupHook = do
              startupHook xfceConfig
              spawn "hsetroot -solid '#131c2b'"
              spawn "snixembed"
              spawn "nm-applet"
              spawn "xfce4-power-manager"
              setWMName "LG3D"
          }
          `additionalKeysP`
          [ ("M-<Return>", spawn "${pkgs.kitty}/bin/kitty")
          , ("M-d", spawn "xfce4-popup-whiskermenu")
          , ("M-S-e", spawn "xfce4-session-logout")
          ]
      '';
    };
  
    services.xserver.desktopManager.gnome.enable = lib.mkForce false;
    services.xserver.displayManager.gdm.enable = lib.mkForce false;
    services.xserver.displayManager.lightdm.enable = lib.mkForce true;
  
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
              <property name="length" type="double" value="${toString xfceIslands.left.lengthPercent}"/><property name="length-adjust" type="bool" value="false"/><property name="size" type="uint" value="${toString xfceIslands.panelSize}"/>
              <property name="position-locked" type="bool" value="true"/><property name="enable-struts" type="bool" value="false"/>
              <property name="plugin-ids" type="array"><value type="int" value="1"/><value type="int" value="7"/></property>
            </property>
            <property name="panel-2" type="empty">
              <property name="position" type="string" value="p=0;x=${toString xfceIslands.center.centerX};y=${toString xfceIslands.centerY}"/>
              <property name="length" type="double" value="${toString xfceIslands.center.lengthPercent}"/><property name="length-adjust" type="bool" value="false"/><property name="size" type="uint" value="${toString xfceIslands.panelSize}"/>
              <property name="position-locked" type="bool" value="true"/><property name="enable-struts" type="bool" value="false"/>
              <property name="plugin-ids" type="array"><value type="int" value="12"/></property>
            </property>
            <property name="panel-3" type="empty">
              <property name="position" type="string" value="p=0;x=${toString xfceIslands.right.centerX};y=${toString xfceIslands.centerY}"/>
              <property name="length" type="double" value="${toString xfceIslands.right.lengthPercent}"/><property name="length-adjust" type="bool" value="false"/><property name="size" type="uint" value="${toString xfceIslands.panelSize}"/>
              <property name="position-locked" type="bool" value="true"/><property name="enable-struts" type="bool" value="false"/>
              <property name="plugin-ids" type="array"><value type="int" value="6"/><value type="int" value="8"/><value type="int" value="9"/><value type="int" value="10"/></property>
            </property>
            <property name="panel-4" type="empty">
              <property name="position" type="string" value="p=0;x=${toString xfceIslands.power.centerX};y=${toString xfceIslands.centerY}"/>
              <property name="length" type="double" value="${toString xfceIslands.power.lengthPercent}"/><property name="length-adjust" type="bool" value="false"/><property name="size" type="uint" value="${toString xfceIslands.panelSize}"/>
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
            <property name="ThemeName" type="string" value="Adwaita-dark"/>
          </property>
        </channel>
      '';
      "gtk-3.0/gtk.css".text = ''
        #XfcePanelWindow {
          background: ${xfceIslands.fill};
          border: ${toString xfceIslands.outline}px solid ${xfceIslands.outlineColor};
          border-radius: ${toString xfceIslands.radius}px;
          box-shadow: none;
          color: #f4effa;
          font-family: "JetBrainsMono Nerd Font";
          font-size: 11px;
          margin: 0;
          padding: 0;
        }
        #clock-button {
          padding-left: 22px;
          padding-right: 22px;
        }
        /* External GtkPlug wrappers have ARGB visuals. Keep every wrapper pixel
           transparent so parent panel chrome remains visible and clickable. */
        #XfcePanelWindowWrapper,
        #XfcePanelWindowWrapper *,
        #sn-button-box,
        #sn-button-box *,
        .-vala-panel-appmenu-core,
        .-vala-panel-appmenu-core *,
        menubar.-vala-panel-appmenu-private,
        menubar.-vala-panel-appmenu-private * {
          background: transparent;
          background-image: none;
          border: 0;
          border-radius: 0;
          box-shadow: none;
        }
        #XfcePanelWindowWrapper {
          color: #f4effa;
          font-family: "JetBrainsMono Nerd Font";
          font-size: 11px;
        }
        /* Native wrapper allocation covers parent inner border rows. Repaint
           only its own body and horizontal inner-border pixels. */
        #XfcePanelWindowWrapper {
          background-color: #0e1624;
          border-top: 1px solid #b75681;
          border-right: 0;
          border-bottom: 1px solid #b75681;
          border-left: 0;
        }
        #whiskermenu-button, #sn-button, #pulseaudio-button,
        #xfce4-power-manager-plugin, #xfce4-notification-plugin, #actions-button {
          color: #f4effa;
          padding: 2px 6px;
        }
        .-vala-panel-appmenu-private > menuitem {
          font-size: 10px;
          padding: 2px 3px;
        }
        #whiskermenu-button:hover, #sn-button:hover, #pulseaudio-button:hover,
        #xfce4-power-manager-plugin:hover, #xfce4-notification-plugin:hover,
        #actions-button:hover, .-vala-panel-appmenu-private > menuitem:hover {
          color: #ffffff;
        }
        .whiskermenu,
        .whiskermenu frame,
        .whiskermenu box,
        .whiskermenu scrolledwindow,
        .whiskermenu viewport,
        .whiskermenu treeview,
        .whiskermenu treeview.view {
          background-color: #0e1826;
          background-image: none;
          color: #f4effa;
          border-color: #26344f;
        }
        .whiskermenu {
          border: 1px solid #f05a9d;
          border-radius: 7px;
          font-family: "JetBrainsMono Nerd Font";
          font-size: 10px;
        }
        .whiskermenu entry {
          background-color: #131c2b;
          color: #f4effa;
          border: 1px solid #8b5cf6;
          border-radius: 5px;
          box-shadow: none;
        }
        .whiskermenu button {
          background-color: transparent;
          background-image: none;
          color: #f4effa;
          border: 0;
          box-shadow: none;
        }
        .whiskermenu button:hover,
        .whiskermenu treeview:selected {
          background-color: #6d28d9;
          color: #ffffff;
        }
        tooltip, tooltip.background {
          background-color: #0e1624;
          color: #f4effa;
          border: 2px solid #b75681;
          border-radius: 9px;
          box-shadow: none;
          padding: 4px 7px;
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
    services.xserver.displayManager.autoLogin.enable = lib.mkForce true;
    services.xserver.displayManager.autoLogin.user = "mpontus";
    services.displayManager.autoLogin.enable = lib.mkForce true;
    services.displayManager.autoLogin.user = "mpontus";
  
    users.mutableUsers = lib.mkForce false;
    users.users.mpontus = {
      hashedPassword = lib.mkForce "";
      # VM-only key for SSH-driven UI iteration through loopback forwarding.
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDzyhZA4hmSFf9vhRM4QBEgVuTKkZXCQw0VMByKnGLtc m.pontus@gmail.com"
      ];
    };
    security.pam.services.login.allowNullPassword = true;
    security.pam.services.lightdm.allowNullPassword = true;
    security.pam.services.i3lock.allowNullPassword = true;
    security.pam.services.xfce4-screensaver.allowNullPassword = true;
    services.openssh.settings.PermitEmptyPasswords = lib.mkForce true;
  };
  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings = {
    General = {
        Enable = "Source,Sink,Media,Socket";
        # Disable = "Headset";
        # Enable = "Source,Sink,Headet,Media,Socket";
        # Disable = "Socket";
        # MultiProfile = "multiple";
    };
  };
  programs.vim.enable = true;
  programs.vim.defaultEditor = true;
  programs.fish.enable = true;
  # Enable `locate` command
  services.locate = {
    enable = true;
    locate = pkgs.mlocate;
    interval = "1h";
  };
  programs.npm = {
          enable = true;
          package = pkgs.unstable.nodejs;
          npmrc = ''
            prefix = ''${HOME}/.npm
            min-release-age=7 # days
            ignore-scripts=true
          '';
  };
  environment.localBinInPath = true;
  sops.secrets.ynab_access_token = {
    owner = "mpontus";
    mode = "0400";
  };
  # See https://github.com/sfackler/rust-openssl/issues/1663#issuecomment-1603606249
  environment.variables = {
    PKG_CONFIG_PATH = [ "${pkgs.openssl.dev}/lib/pkgconfig" "${pkgs.zlib.dev}/lib/pkgconfig" ];
  }   ;
  programs.firejail = {
    enable = true;
    wrappedBinaries = {
      code = {
        executable = "${lib.getBin pkgs.unstable.vscode}/bin/code";
        profile = "${pkgs.firejail}/etc/firejail/code.profile";
        extraArgs = [
          "--name=code"
          "--blacklist=/home/mpontus/.aws"
          "--blacklist=/home/mpontus/.docker"
          "--blacklist=/home/mpontus/.gnupg"
          "--blacklist=/home/mpontus/.mcp-auth"
          "--blacklist=/home/mpontus/.netrc"
          "--blacklist=/home/mpontus/.npmrc"
          "--blacklist=/home/mpontus/.password-store"
          "--blacklist=/home/mpontus/.ssh"
          "--blacklist=/home/mpontus/new-password-store"
        ];
      };
    };
  };
  # programs.gnupg.agent.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gtk2;
  };
  networking.extraHosts = ''
    127.0.0.1 localhost
    127.0.0.1 ipfs.local ff
    192.168.1.121 grafana.orangepi argocd.orangepi portainer.orangepi
  '';
  virtualisation.docker.enable = true;
  users.extraGroups.docker.members = ["mpontus"];
  virtualisation.docker.liveRestore = false;
  networking.firewall.allowedTCPPorts = [ 6443 ];
  services.k3s = {
    enable = false;
    role = "server";
    package = pkgs.unstable.k3s;
    # extraFlags =  toString ["--kubelet-arg=v=4"];
  };
  users.extraGroups.k3s.members = ["mpontus"];
  virtualisation.virtualbox.host.enable = false;
  virtualisation.virtualbox.host.enableExtensionPack = false;
  users.extraGroups.vboxusers.members = ["mpontus" "er"];
  programs.steam.enable = true;
  services.joycond.enable = true;

  # this value determines the nixos release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. it‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # did you read the comment?
}
