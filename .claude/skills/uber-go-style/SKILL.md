---
name: uber-go-style
description: 'Write Go code following the Uber Go Style Guide (uber-go/guide). Covers naming, imports, error handling, concurrency, performance, testing patterns, and linting. Use when writing, reviewing, or refactoring any Go code (.go files, go.mod present), when the user mentions "Uber style", "Go style guide", "idiomatic Go", or asks for code review of Go code. Source: https://github.com/uber-go/guide/blob/master/style.md'
---

# Uber Go Style (project skill)

The canonical rule set lives at the repo root. This file is a thin index — open the topic files at the repo root for full rules with Bad/Good code examples.

## Topic files (at repo root)

| File | Read when |
|---|---|
| [../../../style.md](../../../style.md) | Naming, imports, struct/map init, line length, variable scope, raw strings, embedding |
| [../../../guidelines.md](../../../guidelines.md) | Interfaces, receivers, enums, time handling, type assertions, panics, globals, `init()`, `os.Exit` |
| [../../../errors.md](../../../errors.md) | Returning, wrapping (`%w` vs `%v`), naming (`Err*`/`*Error`), handle-once rule |
| [../../../concurrency.md](../../../concurrency.md) | Mutexes, channels, goroutine lifetimes, `sync.WaitGroup`, atomics |
| [../../../performance.md](../../../performance.md) | `strconv` over `fmt`, byte conversion, slice/map capacity hints |
| [../../../testing.md](../../../testing.md) | Test tables, parallel tests, functional options pattern |
| [../../../scripts/lint.sh](../../../scripts/lint.sh) | Run `golangci-lint` with Uber-aligned config |

## Decision shortcuts

- **Empty slice?** Return `nil`, not `[]T{}`. Test emptiness with `len(s) == 0`.
- **Zero-value struct?** `var x T`, not `T{}`.
- **Pointer struct init?** `&T{Name: "x"}`, not `new(T)`.
- **Wrap error?** `fmt.Errorf("get user %q: %w", id, err)` — no `"failed to"`.
- **Goroutine?** Must have stop signal AND wait mechanism.
- **Mutex?** Non-pointer field, never embedded, name it `mu`.
- **Channel?** Size 0 or 1. Larger needs justification.
- **Enum at iota?** `iota + 1` unless 0 is meaningful default.
- **`os.Exit` / `log.Fatal`?** Only in `main()`, ideally once.
- **Top-level unexported `var`/`const`?** Prefix `_` (errors → `err*`).

## Workflow

1. Identify the work: new code, refactor, or review.
2. Open the relevant topic file(s) listed above.
3. Apply rules. Cite the rule name when correcting code (e.g., "Reduce Nesting", "Handle Errors Once").
4. After producing code, mentally check against the decision shortcuts.
5. For finished work, suggest running `scripts/lint.sh` if `golangci-lint` is installed.

## Note

If installed as a **user-level** skill (cloned into `~/.claude/skills/uber-go-style/`), the topic files live at the skill's root — see `../../../SKILL.md` is `<skill-root>/SKILL.md`. The relative paths above resolve to the same place either way when this repo is the skill home.
