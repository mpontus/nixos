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
    ] else [
      (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
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
  virtualisation.vmVariant = { lib, pkgs, ... }: {
    virtualisation.diskSize = 8192;
  
    services.xserver.desktopManager.xfce = {
      enable = true;
      noDesktop = true;
      enableXfwm = false;
    };
  
    services.xserver.windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      extraPackages = hp: [
        hp.xmonad
        hp.xmonad-contrib
        hp.xmonad-extras
      ];
      config = ''
        import XMonad
        import XMonad.Config.Xfce
        import XMonad.Hooks.EwmhDesktops
        import XMonad.Hooks.ManageDocks
        import XMonad.Hooks.SetWMName
        import XMonad.Layout.Spacing
        import XMonad.Util.EZConfig
  
        main :: IO ()
        main = xmonad $ ewmhFullscreen $ ewmh $ docks $ xfceConfig
          { terminal = "xfce4-terminal"
          , modMask = mod4Mask
          , borderWidth = 3
          , normalBorderColor = "#243044"
          , focusedBorderColor = "#89dceb"
          , layoutHook = avoidStruts $ smartSpacingWithEdge 14 $ layoutHook xfceConfig
          , startupHook = do
              startupHook xfceConfig
              spawn "hsetroot -add '#07111f' -add '#102a44' -add '#075985' -gradient 225"
              spawn "polybar-msg cmd quit || true"
              spawn "polybar -q -c /etc/polybar-xmonad/config.ini workspaces"
              spawn "polybar -q -c /etc/polybar-xmonad/config.ini clock"
              spawn "polybar -q -c /etc/polybar-xmonad/config.ini tray"
              spawn "nm-applet"
              spawn "blueman-applet"
              spawn "xfce4-power-manager"
              spawn "xfce4-terminal --title 'XFCE+xmonad VM' --command 'bash -lc \"echo XFCE+xmonad VM session is running.; echo Super+Enter opens a terminal.; echo Super+d opens rofi.; exec bash\"'"
              setWMName "LG3D"
          }
          `additionalKeysP`
          [ ("M-<Return>", spawn "xfce4-terminal")
          , ("M-d", spawn "rofi -show drun -theme /etc/rofi-xmonad/theme.rasi")
          , ("M-n", spawn "nm-connection-editor")
          , ("M-b", spawn "blueman-manager")
          , ("M-p", spawn "xfce4-settings-manager")
          , ("M-S-e", spawn "xfce4-session-logout")
          ]
      '';
    };
  
    services.xserver.desktopManager.gnome.enable = lib.mkForce false;
    services.xserver.displayManager.gdm.enable = lib.mkForce false;
    services.xserver.displayManager.lightdm.enable = lib.mkForce true;
  
    environment.etc."polybar-xmonad/config.ini".text = ''
      [colors]
      bg = #bb111827
      bg-alt = #dd1f2a44
      fg = #e5e7eb
      muted = #8191b2
      accent = #8bd5ff
      warm = #f5c2e7
  
      [bar/base]
      monitor =
      fixed-center = true
      override-redirect = false
      wm-restack = generic
      bottom = false
      height = 28
      radius = 9
      background = ''${colors.bg}
      foreground = ''${colors.fg}
      border-size = 1
      border-color = #b4befe
      padding-left = 2
      padding-right = 2
      module-margin = 2
      font-0 = monospace:size=10;2
      font-1 = Symbols Nerd Font:size=10;2
  
      [bar/workspaces]
      inherit = bar/base
      width = 18%
      offset-x = 8
      offset-y = 8
      modules-center = xworkspaces
  
      [bar/clock]
      inherit = bar/base
      width = 15%
      offset-x = 42.5%
      offset-y = 8
      modules-center = date
  
      [bar/tray]
      inherit = bar/base
      width = 20%
      offset-x = 79%
      offset-y = 8
      modules-center = pulseaudio memory tray
  
      [module/xworkspaces]
      type = internal/xworkspaces
      label-active = %name%
      label-active-foreground = ''${colors.accent}
      label-active-background = ''${colors.bg-alt}
      label-active-padding = 2
      label-occupied = %name%
      label-occupied-foreground = ''${colors.fg}
      label-occupied-padding = 2
      label-empty = %name%
      label-empty-foreground = ''${colors.muted}
      label-empty-padding = 2
  
      [module/date]
      type = internal/date
      interval = 1
      date = %a %d %b | %I:%M %p
      label = %date%
  
      [module/pulseaudio]
      type = internal/pulseaudio
      format-volume = <label-volume>
      label-volume = vol %percentage%%
      label-muted = muted
      label-muted-foreground = ''${colors.warm}
  
      [module/memory]
      type = internal/memory
      interval = 3
      label = ram %percentage_used%%
  
      [module/tray]
      type = internal/tray
      format-margin = 1
      tray-spacing = 8px
      tray-size = 70%
    '';
  
    environment.etc."rofi-xmonad/theme.rasi".text = ''
      * {
        bg: #111827ee;
        bg-alt: #1f2a44ee;
        fg: #e5e7eb;
        muted: #93a4c7;
        accent: #b4befe;
        border: #b4befe;
      }
  
      window {
        width: 52%;
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
        children: [prompt, entry];
        background-color: @bg-alt;
        border-radius: 10px;
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
        lines: 8;
        spacing: 6px;
        fixed-height: true;
        background-color: transparent;
      }
  
      element {
        padding: 9px 10px;
        border-radius: 9px;
        background-color: transparent;
        text-color: @fg;
      }
  
      element selected {
        background-color: @accent;
        text-color: #111827;
      }
  
      element-icon {
        size: 26px;
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
      backend = "glx";
      fade = true;
      fadeDelta = 4;
      shadow = true;
      shadowOffsets = [ (-7) (-7) ];
      shadowOpacity = 0.35;
      settings = {
        corner-radius = 12;
        rounded-corners-exclude = [
          "window_type = 'dock'"
          "window_type = 'desktop'"
        ];
      };
    };
  
    environment.systemPackages = with pkgs; [
      dmenu
      i3status
      polybar
      rofi
      pavucontrol
      hsetroot
      xorg.xsetroot
      xfce.xfce4-terminal
      unstable.upwork
      (callPackage ./pkgs/upwork-wayland { upwork = unstable.upwork; })
      (callPackage ./pkgs/toptracker { })
    ];
  
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
    users.users.mpontus.hashedPassword = lib.mkForce "";
    security.pam.services.login.allowNullPassword = true;
    security.pam.services.lightdm.allowNullPassword = true;
    security.pam.services.i3lock.allowNullPassword = true;
    security.pam.services.xfce4-screensaver.allowNullPassword = true;
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
