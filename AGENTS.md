# NixOS configuration repo instructions

This repo is a literate NixOS flake configuration.

## Source of truth

- Primary source: `readme.org`
- Tangled/generated outputs: `configuration.nix`, `flake.nix`
- Host: `nixosConfigurations.nixos`
- Main user: `mpontus`

When changing NixOS configuration, prefer editing `readme.org` first. Only edit generated files directly when the user explicitly asks, or when keeping generated output in sync with the Org source.

## Literate config conventions

`readme.org` uses Org Babel noweb refs:

- User/Home Manager packages: `#+begin_src nix :noweb-ref home-packages`
- System packages: `#+begin_src nix :noweb-ref system-packages`
- Unfree package allow-list: `#+begin_src nix :noweb-ref unfree-packages`
- Flake inputs: `#+begin_src nix :noweb-ref inputs`
- NixOS modules: `#+begin_src nix :noweb-ref modules`
- General system config: `#+begin_src nix :noweb-ref system-configuration`
- Home Manager config: `#+begin_src nix :noweb-ref home-configuration`
- GNOME keybindings: `#+begin_src nix :noweb-ref dconf-keymap`

For GUI/user apps, add a nearby topic section in `readme.org` with `:noweb-ref home-packages`. Prefer `pkgs.<name>` unless the config already uses `unstable.<name>` for that package class or stable lacks the package/version.

## Workflow

Before editing:

1. Check `git diff -- readme.org configuration.nix flake.nix` and note unrelated pre-existing changes.
2. Locate the relevant section in `readme.org`.

After editing:

1. If generated files were changed or already present, validate syntax:
   - `nix-instantiate --parse configuration.nix`
   - `nix-instantiate --parse flake.nix`
2. If requested, run a stronger check:
   - `nixos-rebuild dry-build --flake .#nixos`
3. Do not run `sudo nixos-rebuild switch` unless explicitly requested.

When summarizing, separate task changes from unrelated pre-existing diffs.

## Pi configuration management

This repo also manages shared Pi coding-agent configuration in a dotfiles-style layout.

- Repo-managed global Pi config source: `pi/agent/`
- Deployed global Pi config: `~/.pi/agent/`
- Project-local Pi config for this repo: `AGENTS.md`, `.pi/`

When changing reusable/global Pi behavior, edit `pi/agent/` first and sync the relevant files to `~/.pi/agent/` if the user wants the changes active immediately. When changing repo-specific behavior, edit `AGENTS.md` or `.pi/`.

After changing repo-managed Pi config, commit only Pi config paths unless the user says not to:

- `AGENTS.md`
- `.pi/`
- `.agents/`
- `pi/agent/`

Never include unrelated Nix changes, secrets, sessions, auth files, caches, or logs in a Pi config commit.
