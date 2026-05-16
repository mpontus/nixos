---
name: nixos-config
description: Work on this literate NixOS flake configuration. Use when adding/removing NixOS or Home Manager packages, editing readme.org, flake.nix, configuration.nix, unfree packages, services, rebuild checks, or troubleshooting NixOS config evaluation.
---

# NixOS Config Skill

This repository is a literate NixOS configuration. This skill is repo-specific and complements the generic global `nixos-general` skill; project instructions take precedence.

## Key facts

- Source of truth: `readme.org`
- Tangled/generated files: `configuration.nix`, `flake.nix`
- Flake host: `.#nixos` / `nixosConfigurations.nixos`
- Main user: `mpontus`
- Home Manager is configured inside `configuration.nix`.

## Editing rules

Prefer editing `readme.org` first. Avoid direct edits to `configuration.nix` or `flake.nix` unless:

1. The user explicitly asks for direct generated-file edits.
2. You are syncing generated output after updating `readme.org`.
3. The task is only validating or inspecting current generated output.

## Common noweb refs in readme.org

Use these Org Babel blocks:

```org
#+begin_src nix :noweb-ref home-packages
package-name
#+end_src
```

- `home-packages`: Home Manager packages for `mpontus`; default for GUI apps and user CLI tools.
- `system-packages`: system-wide packages.
- `unfree-packages`: strings in allowUnfreePredicate, e.g. `"spotify"`.
- `inputs`: flake inputs.
- `modules`: NixOS modules imported by the flake.
- `system-configuration`: general NixOS config.
- `home-configuration`: Home Manager options for `mpontus`.
- `dconf-keymap`: GNOME custom keybindings.

## Package placement guidance

- GUI apps: `home-packages` near the relevant app category.
- Developer CLIs used by `mpontus`: usually `home-packages`.
- Daemons, virtualization, boot/network/system integration: `system-configuration` and possibly `system-packages`.
- Use `pkgs.<name>`/bare package name by default inside `with pkgs;` blocks.
- Use `unstable.<name>` when stable lacks it, the repo already uses unstable for that tool family, or the user asks for latest.
- If package is unfree, add its lib name string to `unfree-packages` too.

## Safe workflow

Before editing:

```bash
git diff -- readme.org configuration.nix flake.nix
```

Mention unrelated pre-existing changes if relevant.

After editing:

```bash
nix-instantiate --parse configuration.nix >/dev/null
nix-instantiate --parse flake.nix >/dev/null
```

If requested by user, run:

```bash
nixos-rebuild dry-build --flake .#nixos
```

Never run this unless explicitly requested:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

## Summary format

Report:

- Files changed.
- Whether `readme.org` and generated files were both updated or only source was updated.
- Validation commands run.
- Any unrelated pre-existing diffs noticed.
- Exact apply command only if user wants it: `sudo nixos-rebuild switch --flake .#nixos`.
