---
description: Sync generated Nix files with readme.org literate source
---
Sync this literate NixOS repo.

`readme.org` is the source of truth; `configuration.nix` and `flake.nix` are tangled outputs.

Tasks:
1. Inspect diffs for `readme.org`, `configuration.nix`, and `flake.nix`.
2. Determine whether generated files are out of sync with Org source.
3. If Emacs/org-babel tangling is available, use it; otherwise make minimal manual sync edits and explain that they are manual.
4. Validate generated Nix syntax with `nix-instantiate --parse configuration.nix` and `nix-instantiate --parse flake.nix`.
5. Do not rebuild or switch unless I ask.
