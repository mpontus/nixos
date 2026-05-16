---
description: Generically add packages to a NixOS/Home Manager/nix-darwin config
argument-hint: "<package names>"
---
Add these packages to this Nix-based system configuration: $ARGUMENTS

Use a safe generic workflow:
- First inspect local repo instructions such as `AGENTS.md` or `CLAUDE.md`.
- Detect the source of truth; do not assume `configuration.nix` is primary.
- Prefer Home Manager/user packages for GUI apps and user CLI tools when available.
- Use system packages/modules for system services, drivers, boot/networking, virtualization, and daemon integration.
- Do not assume host/user names; inspect `flake.nix` if needed.
- Update unfree allow-lists if the package requires it.
- Keep edits minimal and follow repo style.
- Validate with appropriate parse/build/check commands.
- Do not run switch/rebuild commands unless I explicitly ask.
- Separate task changes from unrelated pre-existing diffs.
