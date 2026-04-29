# Uber Go Style — Multi-Tool Rules Pack

Drop-in style configuration for Go projects that teaches AI coding assistants to write code following the [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md).

Works with **Claude Code**, **OpenAI Codex**, **GitHub Copilot (VS Code/JetBrains)**, **Windsurf**, and **Cursor** out of the box.

---

## TL;DR per tool

| Tool | Global (all projects) | Local (one project) |
|---|---|---|
| Claude Code | `git clone … ~/.claude/skills/uber-go-style` | Copy `.claude/skills/uber-go-style/` + `*.md` to project |
| Windsurf | Append `.windsurf/rules/uber-go-style.md` content into `~/.codeium/windsurf/memories/global_rules.md` | Copy `.windsurf/` + topic `*.md` to project |
| Cursor | Paste `.cursor/rules/uber-go-style.mdc` content into Settings → Rules → User Rules | Copy `.cursor/` + topic `*.md` to project |
| GitHub Copilot | Add custom instructions in VS Code settings | Copy `.github/copilot-instructions.md` to project |
| OpenAI Codex | `mkdir -p ~/.codex && cp AGENTS.md ~/.codex/` | Copy `AGENTS.md` + topic `*.md` to project root |

Detailed steps below.

---

## Setup tutorial

### Claude Code

#### Global (recommended for personal machine)

The skill becomes available across **all** Go projects on your user account.

```bash
git clone https://github.com/meiazero/uber-golang-skill ~/.claude/skills/uber-go-style
```

Verify:

```bash
ls ~/.claude/skills/uber-go-style/SKILL.md
```

Restart Claude Code. The skill appears in the available skills list as `uber-go-style` and auto-triggers when you work on `.go` files.

#### Local (per-project)

Use this when you want the rules versioned alongside the project (good for team projects).

```bash
cd your-go-project
git clone https://github.com/meiazero/uber-golang-skill /tmp/uber-go
mkdir -p .claude/skills/uber-go-style
cp -r /tmp/uber-go/.claude/skills/uber-go-style/* .claude/skills/uber-go-style/
cp /tmp/uber-go/{SKILL.md,style.md,guidelines.md,errors.md,concurrency.md,performance.md,testing.md} .
cp -r /tmp/uber-go/scripts .
rm -rf /tmp/uber-go
```

Commit the files. Anyone cloning the repo gets the skill automatically when using Claude Code.

---

### Windsurf

#### Global (work PC — when you can't modify each project)

Windsurf stores user-level rules in a memories file. Append the Go rules to it:

```bash
mkdir -p ~/.codeium/windsurf/memories
curl -fsSL https://raw.githubusercontent.com/meiazero/uber-golang-skill/main/.windsurf/rules/uber-go-style.md \
  >> ~/.codeium/windsurf/memories/global_rules.md
```

Or download via browser and paste the content into Windsurf → **Settings → Memories → Global rules**.

Restart Windsurf. Rules apply to every project you open.

> **If your company restricts `curl` / network access**: open `.windsurf/rules/uber-go-style.md` from this repo on GitHub, copy its content manually, paste it into the Memories panel inside the Windsurf UI.

#### Local (per-project)

```bash
cd your-go-project
git clone https://github.com/meiazero/uber-golang-skill /tmp/uber-go
mkdir -p .windsurf/rules
cp /tmp/uber-go/.windsurf/rules/uber-go-style.md .windsurf/rules/
cp /tmp/uber-go/{style.md,guidelines.md,errors.md,concurrency.md,performance.md,testing.md} .
rm -rf /tmp/uber-go
```

The rule auto-applies on `*.go` files (configured via `trigger: glob` in the frontmatter).

---

### Cursor

#### Global (all projects)

Cursor User Rules apply across every workspace. Two ways:

**A. Via UI (most reliable)**
1. Open Cursor → Settings (`⌘,` / `Ctrl+,`) → **Rules**
2. Click **User Rules** → paste the contents of `.cursor/rules/uber-go-style.mdc` (everything below the `---` frontmatter)
3. Save

**B. Via file (newer Cursor versions)**

```bash
mkdir -p ~/.cursor/rules
curl -fsSL https://raw.githubusercontent.com/meiazero/uber-golang-skill/main/.cursor/rules/uber-go-style.mdc \
  -o ~/.cursor/rules/uber-go-style.mdc
```

#### Local (per-project)

```bash
cd your-go-project
git clone https://github.com/meiazero/uber-golang-skill /tmp/uber-go
mkdir -p .cursor/rules
cp /tmp/uber-go/.cursor/rules/uber-go-style.mdc .cursor/rules/
cp /tmp/uber-go/{style.md,guidelines.md,errors.md,concurrency.md,performance.md,testing.md} .
rm -rf /tmp/uber-go
```

Glob `**/*.go` in the rule frontmatter ensures it only fires on Go files.

---

### GitHub Copilot (VS Code)

#### Global

Copilot doesn't support a global instructions file directly. Use VS Code settings:

1. `Ctrl+Shift+P` → **Preferences: Open User Settings (JSON)**
2. Add:

```json
{
  "github.copilot.chat.codeGeneration.instructions": [
    {
      "file": "~/.config/github-copilot/uber-go-style.md"
    }
  ]
}
```

3. Save the rule body to that path:

```bash
mkdir -p ~/.config/github-copilot
curl -fsSL https://raw.githubusercontent.com/meiazero/uber-golang-skill/main/.github/copilot-instructions.md \
  -o ~/.config/github-copilot/uber-go-style.md
```

#### Local (per-project)

```bash
cd your-go-project
git clone https://github.com/meiazero/uber-golang-skill /tmp/uber-go
mkdir -p .github/instructions
cp /tmp/uber-go/.github/copilot-instructions.md .github/
cp /tmp/uber-go/.github/instructions/go-uber-style.instructions.md .github/instructions/
rm -rf /tmp/uber-go
```

VS Code Copilot picks up `.github/copilot-instructions.md` automatically. The scoped `.github/instructions/*.instructions.md` file applies only to `*.go` files (newer Copilot feature — `applyTo` frontmatter).

---

### OpenAI Codex

#### Global

```bash
mkdir -p ~/.codex
curl -fsSL https://raw.githubusercontent.com/meiazero/uber-golang-skill/main/AGENTS.md \
  -o ~/.codex/AGENTS.md
```

Codex CLI loads `~/.codex/AGENTS.md` for every session.

#### Local (per-project)

```bash
cd your-go-project
git clone https://github.com/meiazero/uber-golang-skill /tmp/uber-go
cp /tmp/uber-go/AGENTS.md .
cp /tmp/uber-go/{style.md,guidelines.md,errors.md,concurrency.md,performance.md,testing.md} .
rm -rf /tmp/uber-go
```

`AGENTS.md` at repo root is the standard convention — Codex (and many other agents) auto-load it.

---

## Verifying your setup

After installing, ask the AI to write a small Go function and check that it follows the rules:

```
Write a Go function that opens a file, reads its contents, and returns the trimmed string. Apply Uber Go style.
```

Expected behavior — the AI should:
- Wrap errors with `fmt.Errorf("...: %w", err)` (no `"failed to"`)
- Use `defer f.Close()`
- Not use `panic` or `os.Exit` outside `main()`
- Return `nil` for empty results, never `""` placeholders without context

If the AI doesn't apply these patterns, the skill isn't loaded — re-check the file paths above.

---

## How the rules are organized

Canonical rules live in topic files at the repo root, each < 500 lines:

- **`SKILL.md`** — entry point with decision shortcuts
- **`style.md`** — naming, imports, struct/map init, line length, variable scope
- **`guidelines.md`** — interfaces, receivers, enums, time, type assertions, panics, globals, `init()`, exit
- **`errors.md`** — error types, wrapping (`%w`/`%v`), naming, handle-once rule
- **`concurrency.md`** — mutexes, channels, goroutine lifetimes, atomics
- **`performance.md`** — `strconv` over `fmt`, byte conversion, capacity hints
- **`testing.md`** — test tables, parallel tests, functional options pattern

Each tool adapter contains a compressed cheatsheet inline. When a topic needs more detail, the agent opens the relevant root file (e.g., `errors.md`) for the verbatim Bad/Good code examples.

---

## Linting

The repo includes a `golangci-lint` wrapper:

```bash
./scripts/lint.sh             # lint ./...
./scripts/lint.sh ./pkg/...   # lint a path
./scripts/lint.sh --fix       # auto-fix where possible
```

If your project has its own `.golangci.yml`, the script uses it. Otherwise it falls back to the Uber-recommended set: `errcheck`, `goimports`, `revive`, `govet`, `staticcheck`.

Install `golangci-lint`: <https://golangci-lint.run/usage/install/>

---

## Updating

For global installs, pull updates periodically:

```bash
# Claude Code
cd ~/.claude/skills/uber-go-style && git pull

# Cursor (file-based install)
curl -fsSL https://raw.githubusercontent.com/meiazero/uber-golang-skill/main/.cursor/rules/uber-go-style.mdc \
  -o ~/.cursor/rules/uber-go-style.mdc

# Codex
curl -fsSL https://raw.githubusercontent.com/meiazero/uber-golang-skill/main/AGENTS.md \
  -o ~/.codex/AGENTS.md
```

For local (per-project) installs, re-run the install commands or use a git submodule if you want to track upstream:

```bash
git submodule add https://github.com/meiazero/uber-golang-skill .uber-go-style
ln -s .uber-go-style/.cursor .cursor    # adapt per tool
git submodule update --remote .uber-go-style
```

---

## License

MIT — see [LICENSE](LICENSE).

This project inherits the MIT license from the [Uber Go Style Guide](https://github.com/uber-go/guide), from which all rules are adapted verbatim. Copyright for the original guide remains with Uber Technologies, Inc.; copyright for the multi-tool packaging in this repo is held by the maintainers.
