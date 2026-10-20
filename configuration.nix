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
        ./xfce-xmonad.nix
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
      (alttab.overrideAttrs (old: {
        version = "unstable-2026-05-21";
        src = fetchFromGitHub {
          owner = "sagb";
          repo = "alttab";
          rev = "9472d0bfaed91f5d139431b84198ccd4e8993a6e";
          hash = "sha256-Cptaz0zdyaIVNvlLIFoSXntrpObbLKdaWnGVwEfGx18=";
        };
        patches = [
          ./alttab-groups.patch
          ./alttab-popup-singleton.patch
          ./alttab-composite-snapshots.patch
          ./alttab-live-damage.patch
          ./alttab-preview-cache.patch
          ./alttab-preview-icons.patch
          ./alttab-raise-when-obscured.patch
        ];
        buildInputs = old.buildInputs ++ [ libxcomposite libxdamage ];
        doCheck = false;
      }))
      xmessage
      arc-theme
      catppuccin-gtk
      colloid-gtk-theme
      graphite-gtk-theme
      gruvbox-dark-gtk
      nordic
      orchis-theme
      pop-gtk-theme
      rose-pine-gtk-theme
      tokyonight-gtk-theme
      ly
      evtest
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
      substituters = [
        "https://cache.nixos.org/"
        "https://codex-cli.cachix.org"
        "https://claude-code.cachix.org"
      ];
      trusted-public-keys = [
        "codex-cli.cachix.org-1:1Br3H1hHoRYG22n//cGKJOk3cQXgYobUel6O8DgSing="
        "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
      ];
    };
      home-manager.users.mpontus = { config, pkgs, ... }: {
        imports = [
          
        ];
    
        home.packages = with pkgs; [
            dconf-editor
          (rofi.override { plugins = [ rofi-calc rofi-emoji ]; })
          fd
          ripgrep
          jq
          libnotify
          pulseaudio
          bluez
          xorg.xrandr
          xclip
          clipnotify
          arandr
          flameshot
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
            (pkgs.writeShellApplication {
              name = "zellij-start";
              runtimeInputs = [ pkgs.zellij pkgs.git pkgs.coreutils ];
              text = ''
                if [[ -n "''${ZELLIJ_SESSION_NAME:-}" ]]; then
                  session=$ZELLIJ_SESSION_NAME
                elif root=$(git rev-parse --show-toplevel 2>/dev/null); then
                  digest=$(printf '%s' "$root" | sha256sum)
                  session="$(basename "$root")-''${digest:0:8}"
                else
                  exec zellij -l welcome
                fi
                # A fresh GUI terminal is a new client, not a nested multiplexer.
                unset ZELLIJ ZELLIJ_SESSION_NAME
                exec zellij attach --create "$session"
              '';
            })
          tilix
          ghostty
          kitty
          wezterm
          guake
          unstable.upwork
          (callPackage ./pkgs/upwork-wayland { upwork = unstable.upwork; })
          (callPackage ./pkgs/toptracker { })
          (unstable.slack.overrideAttrs (old: {
            postInstall = (old.postInstall or "") + ''
              wrapProgram "$out/bin/slack" \
                --prefix LD_LIBRARY_PATH : \
                "${pkgs.lib.makeLibraryPath [ pkgs.libdbusmenu ]}"
            '';
          }))
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
            wmctrl xdotool xkill xorg.xprop xorg.xwininfo
          # unstable.nodejs
          yarn
          pnpm
          # (callPackage ./pkgs/amazon-q-cli { })
          unstable.amazon-q-cli
          unstable.opencode
          unstable.gemini-cli
          inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
          inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
          (unstable.callPackage ./pkgs/pi-coding-agent-latest { })
          unstable.rustc cargo wasm-pack
          guile
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
                command = "emacsclient --create-frame";
              };
            "<Super>i" = {
              name = "Emacs Everyhere";
              command = "emacsclient --eval '(emacs-everywhere)'";
            };
            "<Super>w" = {
              name = "Open new Firefox window";
              command = "firefox --new-window";
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
          home.file.".config/xmonad/xmonad.hs".source =
            config.lib.file.mkOutOfStoreSymlink "/home/mpontus/projects/xmonad-config/xmonad.hs";
        home.file.".local/bin/rofi-hub" = {
          executable = true;
          text = ''
            #!${pkgs.bash}/bin/bash
            set -eu
            export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gnused pkgs.gawk pkgs.gnugrep pkgs.jq pkgs.systemd pkgs.fd pkgs.xdg-utils pkgs.pulseaudio pkgs.bluez pkgs.blueman pkgs.xorg.xrandr pkgs.arandr pkgs.xclip pkgs.xfce.xfce4-session ]}
            rofi="''${ROFI_HUB_ROFI:-${pkgs.rofi.override { plugins = [ pkgs.rofi-calc pkgs.rofi-emoji ]; }}/bin/rofi}"
            xdg_open="''${ROFI_HUB_XDG_OPEN:-xdg-open}"
            xrandr="''${ROFI_HUB_XRANDR:-xrandr}"
            pick() { "$rofi" -dmenu -i -monitor -1 -p "$1" "''${@:2}"; }
            confirm() { printf 'No\nYes\n' | "$rofi" -dmenu -monitor -1 -p "Confirm $1" -no-custom | grep -qx Yes; }
            if [ "''${ROFI_HUB_CHECK:-}" = 1 ]; then
              for command in cat printf sed awk grep sort cut jq systemctl fd pactl blueman-manager arandr xclip xflock4 xfce4-session-logout; do
                command -v "$command" >/dev/null || exit 1
              done
              exit 0
            fi
            action="''${1:-main}"
            filter="''${2:-}"
            case "$action" in
              main)
                set +e
                filter=$("$rofi" -show combi -modi "combi,actions:$HOME/.local/bin/rofi-actions" -combi-modes 'drun,window,actions' -monitor -1 -message 'All destinations · Alt+C calc · Alt+E emoji · Alt+V clipboard · Ctrl+Alt+F files · use !bang to narrow' -kb-custom-1 'Alt+c' -kb-custom-2 'Alt+e' -kb-custom-3 'Alt+v' -kb-custom-4 'Control+Alt+f' -format f)
                result=$?
                set -e
                case "$result" in
                  10) exec "$0" Calculator "$filter" ;;
                  11) exec "$0" Emoji "$filter" ;;
                  12) exec "$HOME/.local/bin/rofi-clipboard" ;;
                  13) exec "$0" Files "$filter" ;;
                  0|1) exit 0 ;;
                  *) exit "$result" ;;
                esac ;;
              Calculator) exec "$rofi" -show calc -modi calc -no-show-match -no-sort -no-history -monitor -1 -message 'Enter copies result · Esc returns' -filter "$filter" ;;
              Emoji) exec "$rofi" -show emoji -modi emoji -monitor -1 -message 'Select emoji · Esc returns' -filter "$filter" ;;
              Files) f=$(fd --type f --hidden --exclude .git . "$HOME" | sed "s|^$HOME/||" | pick Files -filter "$filter") && "$xdg_open" "$HOME/$f" ;;
              Audio) q=$(printf 'Output device\nMicrophone\n' | pick Audio) || exit 0; case "$q" in 'Output device') s=$(pactl list short sinks | cut -f2 | pick 'Default output') && pactl set-default-sink "$s" ;; Microphone) s=$(pactl list short sources | cut -f2 | pick 'Default microphone') && pactl set-default-source "$s" ;; esac ;;
              Bluetooth) exec blueman-manager ;;
              Displays) q=$(printf 'Open ARandR\nLaptop only\nMirror to projector\n' | pick Displays) || exit 0; case "$q" in 'Open ARandR') exec arandr ;; 'Laptop only') confirm "$q" && "$xrandr" --output eDP-1 --auto $("$xrandr" | awk '/ connected/ && $1 != "eDP-1" {printf " --output %s --off",$1}') ;; 'Mirror to projector') external=$("$xrandr" | awk '/ connected/ && $1 != "eDP-1" {print $1; exit}'); [ -n "$external" ] || exit 0; confirm "$q" && "$xrandr" --output eDP-1 --auto --output "$external" --auto --same-as eDP-1 ;; esac ;;
              Lock) xflock4 ;;
              Suspend|Reboot|'Shut down'|'Log out') confirm "$action" || exit 0; case "$action" in Suspend) systemctl suspend ;; Reboot) systemctl reboot ;; 'Shut down') systemctl poweroff ;; 'Log out') xfce4-session-logout --logout ;; esac ;;
            esac
          '';
        };
        home.file.".local/bin/rofi-actions" = {
          executable = true;
          text = ''
            #!${pkgs.bash}/bin/bash
            set -eu
            export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gnused pkgs.gawk pkgs.gnugrep pkgs.findutils pkgs.fd pkgs.openssh pkgs.kitty pkgs.xdg-utils pkgs.xclip ]}
            hub="''${ROFI_ACTIONS_HUB:-$HOME/.local/bin/rofi-hub}"
            xdg_open="''${ROFI_HUB_XDG_OPEN:-xdg-open}"
            emit() { printf '%s\0info\x1f%s\n' "$1" "$2"; }
            clean() { tr '\n\r' '  ' | cut -c1-180; }
            bookmarks="$HOME/.config/rofi/bookmarks"
            snippets="$HOME/.config/rofi/snippets"
            projects() { [ -d "$HOME/projects" ] && fd --type d --max-depth 4 --hidden --exclude .git . "$HOME/projects" | sort || true; }
            hosts() { awk '/^[[:space:]]*Host[[:space:]]+/ { for(i=2;i<=NF;i++) if ($i !~ /[*?!]/) print $i }' "$HOME/.ssh/config" 2>/dev/null | sort -u || true; }
            if [ "''${ROFI_RETV:-0}" = 0 ]; then
              i=0; while IFS='|' read -r name value; do [ -n "$name" ] && emit "󰖟  $(printf %s "$name" | clean)" "bookmark:$i"; i=$((i+1)); done < "$bookmarks"
              i=0; while IFS= read -r path; do emit "󰘧  $(basename "$path" | clean)" "project:$i"; i=$((i+1)); done < <(projects)
              i=0; while IFS='|' read -r name value; do [ -n "$name" ] && emit "󰩫  $(printf %s "$name" | clean)" "snippet:$i"; i=$((i+1)); done < "$snippets"
              i=0; while IFS= read -r host; do emit "󰣀  $(printf %s "$host" | clean)" "ssh:$i"; i=$((i+1)); done < <(hosts)
              emit '󰕾  Choose audio device' action:Audio
              emit '  Open Bluetooth manager' action:Bluetooth
              emit '󰍹  Configure displays' action:Displays
              emit '󰌾  Lock screen' action:Lock
              emit '󰤄  Suspend' action:Suspend
              emit '󰍃  Log out' 'action:Log out'
              emit '󰜉  Reboot' action:Reboot
              emit '󰐥  Shut down' 'action:Shut down'
              exit 0
            fi
            id="''${ROFI_INFO:-}"
            kind="''${id%%:*}"; index="''${id#*:}"
            case "$index" in *[!0-9]*) [ "$kind" = action ] || exit 0 ;; esac
            case "$kind" in
              bookmark) value=$(sed -n "$((index+1))p" "$bookmarks"); "$xdg_open" "''${value#*|}" ;;
              project) path=$(projects | sed -n "$((index+1))p"); [ -n "$path" ] && exec kitty --directory "$path" ;;
              snippet) value=$(sed -n "$((index+1))p" "$snippets"); printf %s "''${value#*|}" | xclip -selection clipboard ;;
              ssh) host=$(hosts | sed -n "$((index+1))p"); [ -n "$host" ] && exec kitty ssh "$host" ;;
              action) exec "$hub" "$index" ;;
            esac
          '';
        };
        home.file.".local/bin/rofi-clipboard-daemon" = {
          executable = true;
          text = ''
            #!${pkgs.bash}/bin/bash
            set -eu
            export PATH=${lib.makeBinPath [ pkgs.xclip pkgs.clipnotify pkgs.coreutils pkgs.findutils pkgs.util-linux ]}
            umask 077
            dir="''${XDG_RUNTIME_DIR:?}/rofi-clipboard"
            install -d -m 700 "$dir"
            exec 9>"$dir/daemon.lock"
            flock -n 9 || exit 0
            cleanup() { rm -rf "$dir"; }
            trap cleanup EXIT
            trap 'exit 0' HUP INT TERM
            find "$dir" -mindepth 1 ! -name daemon.lock -delete
            while clipnotify; do
              if xclip -selection clipboard -t image/png -o > "$dir/.new" 2>/dev/null && [ -s "$dir/.new" ]; then ext=png
              elif xclip -selection clipboard -t UTF8_STRING -o > "$dir/.new" 2>/dev/null && [ -s "$dir/.new" ]; then ext=txt
              else rm -f "$dir/.new"; continue
              fi
              hash=$(sha256sum "$dir/.new" | cut -c1-12)
              mv "$dir/.new" "$dir/$(date +%s)-$hash.$ext"
              find "$dir" -maxdepth 1 -type f \( -name '*.png' -o -name '*.txt' \) -printf '%T@ %p\n' | sort -rn | tail -n +51 | cut -d ' ' -f2- | xargs -r rm -f
            done
          '';
        };
        home.file.".local/bin/rofi-clipboard" = {
          executable = true;
          text = ''
            #!${pkgs.bash}/bin/bash
            set -eu
            export PATH=${lib.makeBinPath [ pkgs.xclip pkgs.coreutils pkgs.findutils ]}
            rofi="''${ROFI_CLIPBOARD_ROFI:-${pkgs.rofi.override { plugins = [ pkgs.rofi-calc pkgs.rofi-emoji ]; }}/bin/rofi}"
            xclip="''${ROFI_CLIPBOARD_XCLIP:-xclip}"
            dir="''${XDG_RUNTIME_DIR:?}/rofi-clipboard"
            [ -d "$dir" ] || exit 0
            mapfile -d $'\\0' files < <(find "$dir" -maxdepth 1 -type f \( -name '*.png' -o -name '*.txt' \) -printf '%T@ %p\0' | sort -zrn | cut -zd ' ' -f2-)
            [ "''${#files[@]}" -gt 0 ] || exit 0
            index=$(for f in "''${files[@]}"; do case "$f" in *.png) printf 'Image %s\n' "$(basename "$f")" ;; *.txt) printf '%s\n' "$(tr '\n' ' ' < "$f" | cut -c1-100)" ;; esac; done | "$rofi" -dmenu -i -monitor -1 -p Clipboard -format i -no-custom) || exit 0
            [ -n "$index" ] || exit 0
            case "$index" in *[!0-9]*) exit 0 ;; esac
            [ "$index" -lt "''${#files[@]}" ] || exit 0
            f="''${files[$index]}"
            [ -f "$f" ] || exit 0
            case "$f" in *.png) "$xclip" -selection clipboard -t image/png -i "$f" ;; *.txt) "$xclip" -selection clipboard -i "$f" ;; esac
          '';
        };
        xdg.configFile."rofi/bookmarks".text = ''
          NixOS options|https://search.nixos.org/options
          Nix packages|https://search.nixos.org/packages
        '';
        xdg.configFile."rofi/snippets".text = ''
          Shrug|¯\\_(ツ)_/¯
        '';
        xdg.configFile."rofi/config.rasi".text = ''
          configuration {
              modes: "drun,window,run,combi";
              font: "JetBrainsMono Nerd Font 11";
              show-icons: true;
              icon-theme: "Papirus-Dark";
              terminal: "kitty";
              matching: "fuzzy";
              drun-display-format: "{name}";
              display-drun: "Apps";
              display-window: "Windows";
              display-run: "Run";
          }
          @theme "/dev/null"
          * {
              background-color: #0e1624;
              text-color: #f4effa;
              border-color: #b75681;
          }
          window {
              width: 560px;
              location: center;
              anchor: center;
              border: 2px;
              border-radius: 12px;
              padding: 16px;
          }
          mainbox {
              spacing: 12px;
              children: [ inputbar, message, listview ];
          }
          message {
              padding: 0px 8px;
              text-color: #b8f2e6;
          }
          inputbar {
              spacing: 12px;
              padding: 8px;
              children: [ prompt, entry ];
          }
          prompt { text-color: #b8f2e6; }
          entry { placeholder: "Search applications…"; }
          listview {
              lines: 8;
              columns: 1;
              spacing: 4px;
              scrollbar: false;
              fixed-height: false;
          }
          element {
              padding: 10px;
              spacing: 10px;
              border-radius: 6px;
          }
          element selected.normal {
              background-color: #b8f2e6;
              text-color: #0e1624;
          }
          element-icon {
              size: 24px;
              background-color: inherit;
          }
          element-text {
              background-color: inherit;
              text-color: inherit;
              vertical-align: 0.5;
          }
        '';
          programs.emacs = {
            enable = true;
            extraPackages = epkgs: [
              pkgs.typescript
              pkgs.typescript-language-server
              epkgs.magit-delta
            ];
            package = pkgs.symlinkJoin {
              name = "emacs-with-copilot-libs";
              paths = [ pkgs.emacs-gtk pkgs.delta ];
              meta = pkgs.emacs.meta;
              nativeBuildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                wrapProgram $out/bin/emacs --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [
                  pkgs.libsecret
                  pkgs.glib
                  pkgs.stdenv.cc.cc
                ]}
              '';
            };
            # package = pkgs.emacs.withPackages (epkgs: with epkgs; [
            #   vterm
            # ]);
            # package = (pkgs.emacsGit.override {
            #   withXwidgets = true;
            # });
          };
        services.emacs = {
          enable = true;
          socketActivation.enable = true;
          defaultEditor = true;
        };
        programs.firefox =
          let
            # Firefox's native menu loads libdbusmenu dynamically.
            firefoxUnwrapped = pkgs.firefox-beta.unwrapped;
            firefoxWithAppmenu = pkgs.symlinkJoin {
              name = "firefox-beta-unwrapped-appmenu";
              paths = [ firefoxUnwrapped ];
              nativeBuildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                wrapProgram $out/bin/firefox-beta \
                  --prefix LD_LIBRARY_PATH : \
                  "${pkgs.lib.makeLibraryPath [ pkgs.libdbusmenu-gtk3 ]}"
              '';
              inherit (firefoxUnwrapped) applicationName binaryName gtk3 meta;
              passthru = firefoxUnwrapped.passthru;
            };
          in
          {
            enable = true;
            # package = pkgs.unstable.firefox-unwrapped;
            package = firefoxWithAppmenu;
            # Keep existing profile paths while Home Manager writes user.js.
            profiles = {
              default = {
                path = "v2mbprxk.default";
                settings = {
                  "widget.gtk.global-menu.enabled" = true;
                  "widget.gtk.global-menu.wayland.enabled" = true;
                  "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
                };
                userChrome = ''
                  /* Keep Firefox's exported menu from opening an empty local toolbar. */
                  #toolbar-menubar:has(#main-menubar[native]) {
                    display: none !important;
                  }
                  #main-window[customtitlebar] #TabsToolbar > .titlebar-buttonbox-container {
                    display: flex !important;
                    visibility: visible !important;
                  }
                '';
              };
              work = {
                id = 1;
                path = "emrwt21p.work";
              };
            };
          };
        # programs.firefox.package = pkgs.latest.firefox-nightly-bin.unwrapped;
        programs.zellij = {
          enable = true;
          enableBashIntegration = false;
          enableFishIntegration = false;
          enableZshIntegration = false;
          settings = {
            mirror_session = false;
            on_force_close = "detach";
            session_serialization = true;
            default_mode = "locked";
            default_layout = "default";
          };
          extraConfig = ''
            keybinds clear-defaults=true {
              locked {
                bind "Ctrl g" { SwitchToMode "Normal"; }
              }
              normal {
                bind "Ctrl g" { Write 7; SwitchToMode "Locked"; }
                bind "n" { NewTab; SwitchToMode "Locked"; }
                bind "r" { SwitchToMode "RenameTab"; TabNameInput 0; }
                bind "Left" { GoToPreviousTab; SwitchToMode "Locked"; }
                bind "Right" { GoToNextTab; SwitchToMode "Locked"; }
                bind "Tab" { ToggleTab; SwitchToMode "Locked"; }
                bind "s" {
                  LaunchOrFocusPlugin "session-manager" { floating true; move_to_focused_tab true; }
                  SwitchToMode "Locked";
                }
                bind "d" { Detach; }
                bind "v" { NewPane "Right"; SwitchToMode "Locked"; }
                bind "h" { NewPane "Down"; SwitchToMode "Locked"; }
                bind "o" { FocusNextPane; SwitchToMode "Locked"; }
                bind "f" { ToggleFocusFullscreen; SwitchToMode "Locked"; }
                bind "[" { SwitchToMode "Scroll"; }
              }
              scroll {
                bind "Up" { ScrollUp; }
                bind "Down" { ScrollDown; }
                bind "PageUp" { PageScrollUp; }
                bind "PageDown" { PageScrollDown; }
              }
              renametab {
                bind "Esc" { UndoRenameTab; SwitchToMode "Locked"; }
              }
              shared_except "locked" {
                bind "Enter" { SwitchToMode "Locked"; }
              }
              shared_except "locked" "renametab" {
                bind "Esc" { SwitchToMode "Locked"; }
              }
            }
          '';
        };
          programs.tmux = {
            enable = true;
            prefix = "C-a";
            extraConfig = ''
              unbind C-b
              bind C-a send-prefix
            '';
          };
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
    home-manager.backupFileExtension = "hm-backup";
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
      virtualisation.vmVariant = {
        services.displayManager.autoLogin = {
          enable = lib.mkForce true;
          user = lib.mkForce "mpontus";
        };
        services.openssh.enable = true;
        users.users.mpontus = {
          hashedPassword = lib.mkForce "";
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDzyhZA4hmSFf9vhRM4QBEgVuTKkZXCQw0VMByKnGLtc m.pontus@gmail.com"
          ];
        };
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
    networking.hosts."127.0.0.1" = [ "smokeping.local" ];
    services.smokeping = {
      enable = true;
      host = "smokeping.local";
      hostName = "smokeping.local";
      cgiUrl = "http://smokeping.local/smokeping.fcgi";
      owner = "mpontus";
      ownerEmail = "mpontus@localhost";
      databaseConfig = ''
        step = 10
        pings = 10
        # consfn mrhb steps total
        AVERAGE 0.5 1   8640
        AVERAGE 0.5 6  10080
            MIN 0.5 6  10080
            MAX 0.5 6  10080
        AVERAGE 0.5 360 8760
            MIN 0.5 360 8760
            MAX 0.5 360 8760
      '';
      targetConfig = ''
        probe = FPing
        menu = Top
        title = Network latency and packet loss
        + Network
        menu = Network
        title = Local router and Internet
        ++ Router
        menu = Router
        title = Router (192.168.1.254)
        host = 192.168.1.254
        ++ Cloudflare
        menu = Cloudflare
        title = Cloudflare DNS (1.1.1.1)
        host = 1.1.1.1
        ++ Google
        menu = Google
        title = Google DNS (8.8.8.8)
        host = 8.8.8.8
      '';
    };
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
      services.xserver.xkb.layout = "us,ru";
      services.xserver.xkb.options = "grp:win_space_toggle,ctrl:swapcaps";
      i18n.inputMethod.enable = false;
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
    services.usbmuxd.enable = true;
    programs.vim.enable = true;
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
    virtualisation.oci-containers = {
      backend = "docker";
      containers.obkio = {
        image = "obkio/supervisor:latest";
        autoStart = true;
        privileged = true;
        environment = {
          AGENT_ID = "57626538";
          AGENT_SECRET_KEY = "Eqm87EwtARsTgDEUXxbboOmvWRj_AG0-axMHZlUvXTGs6O7yFVS3FNx7LM30k5TN";
        };
        volumes = [ "/var/lib/obkio:/opt/obkio" ];
        extraOptions = [ "--network=host" ];
      };
    };
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
