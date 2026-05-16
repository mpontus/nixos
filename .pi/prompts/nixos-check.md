---
description: Validate the NixOS flake/literate config without switching
---
Check this NixOS configuration safely.

Steps:
1. Inspect `git diff -- readme.org configuration.nix flake.nix` and identify unrelated changes.
2. Validate syntax with:
   - `nix-instantiate --parse configuration.nix`
   - `nix-instantiate --parse flake.nix`
3. If syntax passes and it seems useful, ask before running `nixos-rebuild dry-build --flake .#nixos`.
4. Do not run `sudo nixos-rebuild switch`.
5. Summarize failures with file paths and likely fixes.
