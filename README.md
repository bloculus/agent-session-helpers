# agent-session-helpers

Claude Code session management for any dev project — auto git sync, auto-commit, and session skills.

## What it is

A small set of hooks and skills that wire Claude Code to your project's git workflow:

| Component | What it does |
|---|---|
| `hooks/session_start_hook.sh` | Auto git sync at session start + injects a context file (CHANGELOG.md by default) |
| `hooks/stop_hook.sh` | Auto commit + push at session end (if `session_save` was run) |
| `skills/session_save/` | End-of-session skill: updates TODO.md / ARCHITECTURE.md / CLAUDE.md / CHANGELOG.md, then writes the commit message |
| `skills/session_handoff/` | Creates a self-contained handoff file to pass work to another agent or session |

**Why:** without this, Claude Code has no memory of your project between sessions, doesn't sync with git, and you lose work when context resets.

## How to install

Give the URL of this page to Claude Code and ask it to follow the installation guide below.

---

## Installation guide (for Claude Code)

> You are about to install the agent-session-helpers system in a project. Follow each step in order.

### Prerequisites

- The project must be a git repository with a remote (`git remote -v` should return something).
- You must have write access to the remote.

### Step 1 — Create the `.claude/` directory structure

```bash
mkdir -p .claude/hooks .claude/skills/session_save .claude/skills/session_handoff
```

### Step 2 — Fetch and copy the hook scripts

Fetch the two hook files from this repository and write them to `.claude/hooks/`:

- `https://raw.githubusercontent.com/bloculus/agent-session-helpers/main/hooks/stop_hook.sh` → `.claude/hooks/stop_hook.sh`
- `https://raw.githubusercontent.com/bloculus/agent-session-helpers/main/hooks/session_start_hook.sh` → `.claude/hooks/session_start_hook.sh`

Make them executable:

```bash
chmod +x .claude/hooks/stop_hook.sh .claude/hooks/session_start_hook.sh
```

**Optional:** open `.claude/hooks/session_start_hook.sh` and change the `CONTEXT_FILE` variable (line ~14) to any file you prefer to inject at session start. Default is `CHANGELOG.md`. Other options: `README.md`, `TODO.md`, or any other file.

### Step 3 — Copy the skills

Fetch and write:

- `https://raw.githubusercontent.com/bloculus/agent-session-helpers/main/skills/session_save/SKILL.md` → `.claude/skills/session_save/SKILL.md`
- `https://raw.githubusercontent.com/bloculus/agent-session-helpers/main/skills/session_handoff/SKILL.md` → `.claude/skills/session_handoff/SKILL.md`

### Step 4 — Create `.claude/settings.json`

Fetch and write:

- `https://raw.githubusercontent.com/bloculus/agent-session-helpers/main/settings.json` → `.claude/settings.json`

### Step 5 — Create the four project documentation files

These files are the backbone of the session system. Generate their content based on what you know about the current project.

**`CLAUDE.md`** — Project instructions for Claude Code. Must include:
- A **"Carte de la documentation"** table listing CLAUDE.md, ARCHITECTURE.md, TODO.md, CHANGELOG.md
- A **"Cycle de session"** section explaining: SessionStart hook → work → `/session_save` → Stop hook
- Project overview (what it is, repo URL, who uses it)
- Tech stack
- Dev rules (language conventions, key constraints)
- Build/run commands
- A **"Workflow"** section that includes: "Propose `/session_save` at the end of each task — never invoke it automatically"

**`ARCHITECTURE.md`** — Technical architecture of the project (components, data flow, key files, tech stack).

**`TODO.md`** — Task and bug tracker. Suggested format:

```markdown
# TODO — [Project Name]

## Features / Tasks

| ID | Description | Status | Next action |
|---|---|---|---|
| FEAT-1 | ... | ✅ Done / 🟡 In progress / ⚪ Backlog | ... |

## Known issues

| ID | Description | Status | Next action |
|---|---|---|---|
| BUG-1 | ... | 🟡 Investigating | ... |
```

**`CHANGELOG.md`** — Version history. Suggested format:

```markdown
# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Versioning: +0.1 per release, next integer for major rewrites.

## [Unreleased]

## [x.y.z] - YYYY-MM-DD

### Added
- ...

### Fixed
- ...
```

### Step 6 — Create `.claude/settings.local.json` (not versioned)

This file holds per-machine Bash permission allowlists. It is excluded from git by the global Claude Code gitignore (`.config/git/ignore`), so each user creates their own.

Create `.claude/settings.local.json` with the Bash permissions required by your project's tech stack. Examples:

```json
{
  "permissions": {
    "allow": [
      "Bash(git *)",
      "Bash(npm *)",
      "Bash(node *)",
      "Bash(grep:*)",
      "Bash(find:*)",
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(chmod:*)",
      "WebSearch",
      "WebFetch"
    ]
  }
}
```

Adapt the list to your stack (e.g. replace `npm` with `cargo`, `go`, `python`, etc.).

### Step 7 — Commit everything

```bash
git add CLAUDE.md ARCHITECTURE.md TODO.md CHANGELOG.md .claude/settings.json .claude/hooks/ .claude/skills/
git commit -m "chore: add Claude Code session management (agent-session-helpers)"
git push
```

> `.claude/settings.local.json` is intentionally excluded from this commit — it's machine-specific.

### Step 8 — Verify

1. Open the project in Claude Code — the SessionStart hook should run, sync git, and inject the context file.
2. Do some work, then run `/session_save` — it should update the doc files and write `.claude/session_commit_msg.txt`.
3. End the session — the Stop hook should automatically commit and push.
4. Check GitHub to confirm the commit appears.

---

## Skills reference

### `/session_save`

Runs at the end of a work session. Asks for confirmation, then:
1. Updates `TODO.md` (new tasks, status changes with user confirmation)
2. Updates `ARCHITECTURE.md` (if architecture changed)
3. Proposes `CLAUDE.md` updates (permanent rules, requires confirmation)
4. Adds entries to `CHANGELOG.md [Unreleased]`
5. Writes `.claude/session_commit_msg.txt` — the Stop hook picks it up

### `/session_handoff`

Creates a self-contained `handoff_YYMMDD_[theme].md` file at the project root. Another agent starting cold can read it and continue without needing the conversation history. Also handles loading an existing handoff (Mode REPRISE).
