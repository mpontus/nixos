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
      # Change this to a rev sha to pin
      moz-rev = "master";
      moz-url = builtins.fetchTarball { url = "https://github.com/mozilla/nixpkgs-mozilla/archive/${moz-rev}.tar.gz";
                                        sha256 = "0fcfg835ly29m7m4xzhxb7lvw2ayxcv7cn7pzw4hkj2j1vzx7b2b"; };
      nightlyOverlay = (import "${moz-url}/firefox-overlay.nix");
    in nightlyOverlay)
    (import (builtins.fetchTarball
    {
      url =     "https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz";
      sha256 = "0fcfg835ly29m7m4xzhxb7lvw2ayxcv7cn7pzw4hkj2j1vzx7b2b";
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
    allowed-users = [ "mpontus" ];
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
      enable = true;
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
        nerd-fonts.fira-code
  nerd-fonts.droid-sans-mono
      ];
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
  services.xserver.desktopManager.gnome.enable = true;
  systemd.services."getty@tty1".enable = true;
  systemd.services."autovt@tty1".enable = true;
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "mpontus";
  services.xserver.windowManager.dwm.enable = true;
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
      code-untrusted = {
        executable = "${lib.getBin pkgs.unstable.vscode}/bin/code";
        extraArgs = [
          "--name=code-untrusted"
          "--private-cache"
          "--private-tmp"
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
  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;
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
