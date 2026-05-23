---
name: nixos-general
description: Generic safe workflow for editing NixOS, Home Manager, nix-darwin, and flake-based configuration repositories. Use when adding packages, changing modules/options, validating flakes, troubleshooting Nix evaluation errors, or planning rebuild commands.
---

# Generic NixOS Configuration Skill

Use this skill for NixOS, Home Manager, nix-darwin, and flake-based system configuration work.

## Priority

Project-local instructions take precedence over this generic skill. Before making assumptions, inspect and obey:

- `AGENTS.md`
- `CLAUDE.md`
- `.pi/skills/*/SKILL.md`
- `.pi/prompts/*`
- repository README files or comments describing generation/literate workflows

Do not assume every repo uses the same structure.

## First inspect the repo

Before editing, determine:

- Is this a flake repo? Look for `flake.nix` and outputs such as `nixosConfigurations`, `homeConfigurations`, or `darwinConfigurations`.
- What is the source of truth? It may be `configuration.nix`, `home.nix`, module files, `readme.org`, `README.md`, `flake.nix`, or generated/tangled files.
- Are there generated files? If yes, edit the source file first and only sync generated files intentionally.
- What hosts/users exist? Do not assume names like `nixos`, `mpontus`, or `home`.
- Are packages split between system packages and user/Home Manager packages?

Check current changes first:

```bash
git status --short
git diff -- flake.nix configuration.nix home.nix modules readme.org README.md
```

If tracked or relevant untracked changes already exist, preserve them before starting new work:

- Review the diff enough to understand what belongs together.
- Commit existing changes as one or more atomic commits before editing.
- Never mix pre-existing work with the new requested change.
- If existing changes are ambiguous, risky, secret-looking, or not ready to commit, ask the user before proceeding.
- Leave clearly unrelated untracked secrets, caches, logs, or artifacts uncommitted unless the user explicitly asks.

Report unrelated pre-existing changes separately from task changes.

## Editing guidance

- Prefer minimal, focused edits.
- For GUI apps and user CLI tools, prefer Home Manager packages when the repo uses Home Manager.
- For system services, drivers, boot, networking, virtualization, users, fonts, or daemon config, use NixOS/nix-darwin modules.
- Use stable package names by default.
- Use unstable inputs only if the repo already has an unstable package set and there is a reason: missing package, needed version, or existing convention.
- For unfree packages, update the repo's unfree allow-list if one exists.
- Preserve formatting and local style.

## Validation

Pick validation commands that match the repo. Common options:

```bash
nix flake check
nix-instantiate --parse configuration.nix
nix-instantiate --parse flake.nix
nixos-rebuild dry-build --flake .#HOST
home-manager build --flake .#USER@HOST
nix build .#nixosConfigurations.HOST.config.system.build.toplevel
```

If the host/user name is unknown, inspect `flake.nix` rather than guessing.

Never run destructive or privileged commands unless explicitly requested, especially:

```bash
sudo nixos-rebuild switch
sudo nixos-rebuild boot
nixos-rebuild switch
home-manager switch
```

It is fine to suggest the exact apply command after validation, clearly labeled as something for the user to run.

## Commit workflow

After making changes:

1. Run appropriate validation first.
2. Commit successful work as atomic commits.
3. Commit source-of-truth edits and their generated outputs together when they represent the same logical change.
4. Keep unrelated changes out of the task commit. Use pathspecs or interactive staging when needed.
5. Do not commit if validation fails, unless the user explicitly asks to save a failing checkpoint.
6. Do not amend, rebase, reset, or rewrite existing commits unless explicitly requested.

## Summary checklist

When done, summarize:

- Files changed.
- Whether source files or generated files were edited.
- Validation commands run and results.
- Commit hash(es) created.
- Any unrelated remaining diffs.
- Suggested apply command, only if appropriate.
