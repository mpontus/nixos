---
name: pi-config
description: Manage Pi coding agent configuration, including AGENTS.md, .pi project config, global ~/.pi/agent skills/prompts/extensions/themes, and repo-managed dotfiles-style Pi config. Use when changing Pi skills, prompt templates, extensions, themes, settings, or agent instructions.
---

# Pi Config Skill

Use this skill when modifying Pi configuration, skills, prompts, extensions, themes, settings, or repo instructions for Pi/agents.

## Read docs first

For Pi-specific implementation details, read the relevant Pi docs before editing:

- Main docs: `/nix/store/dkwsaf5g95359yb6i5z3idw5l8z9h5ps-pi-coding-agent-0.70.5/lib/node_modules/pi-monorepo/README.md`
- Skills: `docs/skills.md`
- Prompt templates: `docs/prompt-templates.md`
- Extensions: `docs/extensions.md`
- Themes: `docs/themes.md`
- Settings: `docs/settings.md`
- Packages: `docs/packages.md`

## Config locations

Distinguish these cases:

- Project-local Pi config:
  - `AGENTS.md`
  - `.pi/`
  - `.agents/`
- Deployed global Pi config:
  - `~/.pi/agent/`
  - `~/.agents/`
- Repo-managed global Pi dotfiles source in this repo:
  - `pi/agent/`

In this repo, `pi/agent/` is the source of truth for shared global Pi config. `~/.pi/agent/` is the deployed copy.

## Editing policy

- For project-specific behavior, edit project-local files (`AGENTS.md`, `.pi/`, `.agents/`).
- For reusable global behavior, edit `pi/agent/` first, then sync to `~/.pi/agent/` if needed for immediate use.
- Do not treat arbitrary `~/.pi` contents as safe to commit. Avoid sessions, auth files, caches, logs, provider credentials, and local settings unless explicitly requested and reviewed.
- Prefer skills/prompts for workflow guidance before writing extensions.
- Use extensions only when behavior must be enforced programmatically or needs custom tools/UI/events.

## Commit policy

After changing repo-managed Pi config, commit the Pi config changes unless the user says not to.

Allowed commit paths for Pi config commits:

- `AGENTS.md`
- `.pi/`
- `.agents/`
- `pi/agent/`

Before committing:

```bash
git status --short
git diff -- AGENTS.md .pi .agents pi/agent
git diff --check -- AGENTS.md .pi .agents pi/agent
```

Commit only allowlisted Pi config paths. Do not include unrelated Nix config, secrets, generated outputs, sessions, caches, or research artifacts.

Default commit message:

```text
Update pi configuration
```

Use a more specific message when obvious, for example:

```text
Add pi NixOS workflow skills
```

## Deployment sync

When `pi/agent/` changes and the user wants the global config active now, sync relevant files to `~/.pi/agent/` using targeted copies, for example:

```bash
mkdir -p ~/.pi/agent/skills ~/.pi/agent/prompts
cp -r pi/agent/skills/NAME ~/.pi/agent/skills/
cp pi/agent/prompts/NAME.md ~/.pi/agent/prompts/
```

Avoid broad `rsync --delete` unless the user explicitly wants global config pruning.

## Auto-commit extension guidance

Do not create an automatic post-edit commit extension by default. It is risky in dirty repos. If automation is requested, prefer an explicit command/extension that:

- shows the allowlisted diff,
- asks for confirmation,
- stages only allowlisted Pi config paths,
- refuses to commit secrets or unrelated files.
