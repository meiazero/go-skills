---
name: uber-go-style
description: 'Write Go code following the Uber Go Style Guide (uber-go/guide). Covers naming, imports, error handling, concurrency, performance, testing patterns, and linting. Use when writing, reviewing, or refactoring any Go code (.go files, go.mod present), when the user mentions "Uber style", "Go style guide", "idiomatic Go", or asks for code review of Go code. Source: https://github.com/uber-go/guide/blob/master/style.md'
---

# Uber Go Style

Apply these rules whenever writing or reviewing Go. Load the topic file relevant to the current task — do not load all of them upfront.

## Topic index

Read the relevant file(s) before producing code. Each is < 500 lines.

| File | Read when |
|---|---|
| [style.md](style.md) | Naming, imports, struct/map init, line length, variable scope, raw strings, embedding |
| [guidelines.md](guidelines.md) | Interfaces, receivers, enums, time handling, type assertions, panics, globals, `init()`, `os.Exit` |
| [errors.md](errors.md) | Returning, wrapping (`%w` vs `%v`), naming (`Err*`/`*Error`), handle-once rule |
| [concurrency.md](concurrency.md) | Mutexes, channels, goroutine lifetimes, `sync.WaitGroup`, atomics |
| [performance.md](performance.md) | `strconv` over `fmt`, byte conversion, slice/map capacity hints |
| [testing.md](testing.md) | Test tables, parallel tests, functional options pattern |
| [scripts/lint.sh](scripts/lint.sh) | Run `golangci-lint` with Uber-aligned config |

## Decision shortcuts

When in doubt, follow these defaults:

- **Returning empty slice?** Return `nil`, not `[]T{}`. Test emptiness with `len(s) == 0`.
- **Declaring a zero-value struct?** `var x T`, not `T{}`.
- **Initializing a pointer struct?** `&T{Name: "x"}`, not `new(T)`.
- **Wrapping an error?** `fmt.Errorf("get user %q: %w", id, err)` — no `"failed to"`.
- **Goroutine?** It must have a stop signal AND a way to wait for exit.
- **Mutex?** Non-pointer field, never embedded, name it `mu`.
- **Channel?** Size 0 (unbuffered) or 1. Anything larger needs justification.
- **Enum starting at iota?** Use `iota + 1` unless zero is the meaningful default.
- **`os.Exit` / `log.Fatal`?** Only in `main()`, ideally exactly once.
- **Top-level unexported `var`/`const`?** Prefix with `_` (except errors → `err*`).

## Workflow

1. Identify what's being written: new code, refactor, or review.
2. Load the relevant topic file(s).
3. Apply rules. Cite the rule name when correcting code (e.g., "Reduce Nesting", "Handle Errors Once").
4. After producing code, mentally check against the decision shortcuts above.
5. For finished work, suggest running `scripts/lint.sh` if the user has `golangci-lint` installed.

## Source

Full guide: https://github.com/uber-go/guide/blob/master/style.md (verbatim rules preserved across topic files).
