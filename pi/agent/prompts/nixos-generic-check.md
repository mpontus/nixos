---
description: Generically validate a NixOS/Home Manager/nix-darwin config without switching
---
Validate this Nix-based system configuration safely.

Steps:
1. Inspect local repo instructions such as `AGENTS.md` or `CLAUDE.md`.
2. Inspect `git status --short` and relevant diffs; identify unrelated pre-existing changes.
3. Detect whether this repo uses flakes, Home Manager, nix-darwin, generated files, or literate config.
4. Run suitable non-switching checks, such as:
   - `nix flake check`
   - `nix-instantiate --parse configuration.nix`
   - `nix-instantiate --parse flake.nix`
   - `nixos-rebuild dry-build --flake .#HOST`
   - `home-manager build --flake .#USER@HOST`
5. Ask before expensive checks if unsure.
6. Never run `switch`, `boot`, or privileged rebuild commands unless explicitly requested.
7. Summarize errors with file paths and likely fixes.
