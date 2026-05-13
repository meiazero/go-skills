# Go Skills

Two AI-assistant skills based on the [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md):

| Skill | Purpose |
|---|---|
| [`uber-go-style/`](uber-go-style/) | Write/refactor Go code following the guide. Owns the canonical rule files. Includes a `golangci-lint` wrapper. |
| [`go-style-review/`](go-style-review/) | Review Go code or diffs. Emits PR-style comments with rule name + unified-diff fix. **Reads rule content from `uber-go-style/` via `../uber-go-style/<topic>.md`.** |

Designed to be used **together** — install both side by side. The review skill links to the topic files in `uber-go-style/` instead of carrying its own copy, so there is no duplication to drift.

> If you only install `go-style-review`, the topic-file links break. For Claude Code, always install `uber-go-style` alongside it.

---

## Install — Claude Code

### Global (all projects on this machine)

```bash
git clone https://github.com/meiazero/go-skills /tmp/go-skills
mkdir -p ~/.claude/skills
cp -r /tmp/go-skills/uber-go-style    ~/.claude/skills/
cp -r /tmp/go-skills/go-style-review  ~/.claude/skills/
rm -rf /tmp/go-skills
```

Verify both landed as siblings (the review skill's `../uber-go-style/...` links depend on this):

```bash
ls ~/.claude/skills/uber-go-style/SKILL.md
ls ~/.claude/skills/go-style-review/SKILL.md
```

Restart Claude Code. Both skills appear in the available-skills list and auto-trigger on Go work.

### Per-project (versioned with the repo)

```bash
cd your-go-project
git clone https://github.com/meiazero/go-skills /tmp/go-skills
mkdir -p .claude/skills
cp -r /tmp/go-skills/uber-go-style    .claude/skills/
cp -r /tmp/go-skills/go-style-review  .claude/skills/
rm -rf /tmp/go-skills
```

Commit `.claude/skills/`. Teammates pick the skills up automatically.

---

## Install — Windsurf

Only the **write** skill applies (Windsurf has no review mode), so the cross-skill dependency does not come up.

### Global

```bash
git clone https://github.com/meiazero/go-skills /tmp/go-skills
mkdir -p ~/.codeium/windsurf/memories
# Strip the Claude frontmatter, append the rule body to Windsurf's global rules.
awk '/^---$/{c++; next} c>=2' /tmp/go-skills/uber-go-style/SKILL.md \
  >> ~/.codeium/windsurf/memories/global_rules.md
rm -rf /tmp/go-skills
```

Or open `uber-go-style/SKILL.md` in the browser, copy everything **below the second `---`**, and paste it into Windsurf → **Settings → Memories → Global rules**.

### Per-project

```bash
cd your-go-project
git clone https://github.com/meiazero/go-skills /tmp/go-skills
mkdir -p .windsurf/rules
# Build a Windsurf-flavored rules file with the right frontmatter.
{
  printf -- '---\ntrigger: glob\nglobs:\n  - "**/*.go"\ndescription: Uber Go Style — applies to *.go\n---\n\n'
  awk '/^---$/{c++; next} c>=2' /tmp/go-skills/uber-go-style/SKILL.md
} > .windsurf/rules/uber-go-style.md
# Optional: copy the topic files for deep reference.
cp /tmp/go-skills/uber-go-style/{style,guidelines,errors,concurrency,performance,testing}.md .
rm -rf /tmp/go-skills
```

The rule auto-applies on `*.go` files via the glob trigger.

---

## Install — GitHub Copilot (VS Code)

Only the **write** skill applies.

### Per-project (repo-level instructions — recommended)

```bash
cd your-go-project
git clone https://github.com/meiazero/go-skills /tmp/go-skills
mkdir -p .github
# Strip the Claude frontmatter, save as Copilot repo-level instructions.
awk '/^---$/{c++; next} c>=2' /tmp/go-skills/uber-go-style/SKILL.md \
  > .github/copilot-instructions.md
# Optional: copy the topic files for deep reference.
cp /tmp/go-skills/uber-go-style/{style,guidelines,errors,concurrency,performance,testing}.md .
rm -rf /tmp/go-skills
```

VS Code Copilot picks `.github/copilot-instructions.md` up automatically.

### Global (user-level)

Copilot has no native global file. Use VS Code user settings:

1. `Ctrl+Shift+P` → **Preferences: Open User Settings (JSON)**.
2. Add:

   ```json
   {
     "github.copilot.chat.codeGeneration.instructions": [
       { "file": "~/.config/github-copilot/uber-go-style.md" }
     ]
   }
   ```

3. Save the rule body to that path:

   ```bash
   git clone https://github.com/meiazero/go-skills /tmp/go-skills
   mkdir -p ~/.config/github-copilot
   awk '/^---$/{c++; next} c>=2' /tmp/go-skills/uber-go-style/SKILL.md \
     > ~/.config/github-copilot/uber-go-style.md
   rm -rf /tmp/go-skills
   ```

---

## Verifying the install

Ask the AI to write a small Go function:

> Write a Go function that opens a file, reads its contents, and returns the trimmed string. Apply Uber Go style.

The AI should:

- Wrap errors with `fmt.Errorf("...: %w", err)` (no `"failed to"`).
- Use `defer f.Close()`.
- Not use `panic` or `os.Exit` outside `main()`.
- Return `nil` for empty results, not `""` placeholders without context.

If you don't see this behavior, the rules aren't loaded — recheck the paths above.

---

## Linting

`uber-go-style/scripts/lint.sh` wraps `golangci-lint` with the Uber-recommended linter set (`errcheck`, `goimports`, `revive`, `govet`, `staticcheck`).

```bash
uber-go-style/scripts/lint.sh                 # lint ./...
uber-go-style/scripts/lint.sh ./pkg/...       # lint a path
uber-go-style/scripts/lint.sh --fix           # auto-fix where possible
```

If your project has its own `.golangci.yml`, the script uses it; otherwise it falls back to the Uber base set.

Install `golangci-lint`: <https://golangci-lint.run/usage/install/>.

---

## Repo layout

```
go-skills/
├── uber-go-style/          # write skill — canonical home of the rule files
│   ├── SKILL.md
│   ├── scripts/lint.sh
│   ├── style.md
│   ├── guidelines.md
│   ├── errors.md
│   ├── concurrency.md
│   ├── performance.md
│   └── testing.md
├── go-style-review/        # review skill — links to ../uber-go-style/<topic>.md
│   ├── SKILL.md
│   ├── checklist.md
│   └── examples.md
├── LICENSE
└── README.md
```

### Editing the rules

The canonical rule content lives in `uber-go-style/<topic>.md`. Edit there — `go-style-review` reads the same files via relative paths, so no sync step is needed.

---

## Updating an install

```bash
# Claude Code (global)
git clone https://github.com/meiazero/go-skills /tmp/go-skills
rm -rf ~/.claude/skills/uber-go-style ~/.claude/skills/go-style-review
cp -r /tmp/go-skills/uber-go-style    ~/.claude/skills/
cp -r /tmp/go-skills/go-style-review  ~/.claude/skills/
rm -rf /tmp/go-skills
```

For Windsurf / Copilot, re-run the install snippet — it overwrites the previous rule file.

---

## License

MIT — see [LICENSE](LICENSE).

Rule content is adapted verbatim from the [Uber Go Style Guide](https://github.com/uber-go/guide), also MIT-licensed. Copyright for the original guide remains with Uber Technologies, Inc.; copyright for the multi-tool packaging in this repo is held by the maintainers.
