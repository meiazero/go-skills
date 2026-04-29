# Uber Go Style — Multi-Tool Rules Pack

Drop-in style configuration for Go projects that teaches AI coding assistants to write code following the [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md).

Works with **Claude Code**, **OpenAI Codex**, **GitHub Copilot (VS Code/JetBrains)**, **Windsurf**, and **Cursor** out of the box.

## What's inside

| Path | Purpose |
|---|---|
| `SKILL.md` + `*.md` (root) | Canonical rule set — full Uber Go Style Guide split by topic |
| `scripts/lint.sh` | `golangci-lint` wrapper with Uber-recommended config fallback |
| `AGENTS.md` | OpenAI Codex / generic agent standard |
| `.github/copilot-instructions.md` | GitHub Copilot (VS Code, JetBrains, etc.) |
| `.cursor/rules/uber-go-style.mdc` | Cursor rules (auto-applies on `*.go`) |
| `.windsurf/rules/uber-go-style.md` | Windsurf rules (auto-applies on `*.go`) |
| `.claude/skills/uber-go-style/SKILL.md` | Claude Code project-level skill |

The **canonical content** is the set of `*.md` files at the repo root. Tool-specific adapter files reference back to them — when a topic comes up that isn't covered by the inline cheatsheet, the agent opens the relevant root file (e.g., `errors.md`).

## Install

### Option A — Drop into your Go project (works for all tools)

```bash
cd your-go-project
git clone https://github.com/meiazero/uber-golang-skill .uber-golang-skill
# Move tool-specific files into place (or symlink)
cp -r .uber-golang-skill/AGENTS.md .uber-golang-skill/.cursor .uber-golang-skill/.windsurf .uber-golang-skill/.github .uber-golang-skill/.claude .
```

Each tool will pick up its own config automatically.

### Option B — Use as a Claude Code user-level skill

```bash
git clone https://github.com/meiazero/uber-golang-skill ~/.claude/skills/uber-go-style
```

Claude Code will auto-load the skill whenever you work on Go code.

### Option C — Selective install per tool

Pick the file(s) you need:

| Tool | File(s) to copy into your repo |
|---|---|
| Claude Code (project) | `.claude/skills/uber-go-style/` + root `*.md` files |
| Claude Code (user) | clone whole repo to `~/.claude/skills/uber-go-style/` |
| OpenAI Codex | `AGENTS.md` + root `*.md` files |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Cursor | `.cursor/rules/uber-go-style.mdc` |
| Windsurf | `.windsurf/rules/uber-go-style.md` |

## How the rules are organized

The canonical rules live in topic files at the repo root, each < 500 lines:

- **`style.md`** — naming, imports, struct/map init, line length, variable scope
- **`guidelines.md`** — interfaces, receivers, enums, time, type assertions, panics, globals, `init()`, exit
- **`errors.md`** — error types, wrapping (`%w`/`%v`), naming, handle-once rule
- **`concurrency.md`** — mutexes, channels, goroutine lifetimes, atomics
- **`performance.md`** — `strconv` over `fmt`, byte conversion, capacity hints
- **`testing.md`** — test tables, parallel tests, functional options pattern

`SKILL.md` is the entry point with decision shortcuts. Each tool adapter contains a compressed cheatsheet inline plus pointers to these topic files.

## Linting

After installing, run:

```bash
./scripts/lint.sh             # lint ./...
./scripts/lint.sh ./pkg/...   # lint a path
./scripts/lint.sh --fix       # auto-fix
```

If your project has its own `.golangci.yml`, the script uses it. Otherwise it falls back to the Uber-recommended linter set: `errcheck`, `goimports`, `revive`, `govet`, `staticcheck`.

## Source

All rules adapted verbatim from <https://github.com/uber-go/guide/blob/master/style.md> (MIT-licensed).
