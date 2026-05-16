---
description: Add packages to the literate NixOS/Home Manager config
argument-hint: "<package names>"
---
Add these packages to my NixOS configuration: $ARGUMENTS

Follow repo conventions:
- `readme.org` is the source of truth.
- Prefer adding GUI/user apps to `home-packages` for `mpontus`.
- Use `system-packages` only for system-level tools/services.
- Add packages near the relevant topic section, creating a small Org heading if needed.
- Keep `configuration.nix` in sync if appropriate.
- Check for and report unrelated pre-existing diffs.
- Validate with `nix-instantiate --parse configuration.nix`.
- Do not run `sudo nixos-rebuild switch` unless I explicitly ask.
