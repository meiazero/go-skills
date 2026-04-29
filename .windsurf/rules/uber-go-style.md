---
trigger: glob
globs:
  - "**/*.go"
description: Uber Go Style Guide — applies automatically when editing Go files.
---

# Uber Go Style

Source: <https://github.com/uber-go/guide/blob/master/style.md>. Full rules with Bad/Good examples: read the topic files at the repo root — `style.md`, `guidelines.md`, `errors.md`, `concurrency.md`, `performance.md`, `testing.md`.

## Decision defaults

- **Empty slice** → return `nil`, not `[]T{}`. Test emptiness with `len(s) == 0`.
- **Zero-value struct** → `var x T`, not `T{}`.
- **Pointer struct init** → `&T{Field: v}`, not `new(T)`.
- **Wrap error** → `fmt.Errorf("context: %w", err)`. Never `"failed to"`.
- **Goroutine** → stop signal + wait mechanism, always.
- **Mutex** → non-pointer field, never embedded, named `mu`.
- **Channel** → unbuffered or size 1.
- **Enum** → `iota + 1` unless 0 is the meaningful default.
- **Exit** → only in `main()`, ideally once via `run()` helper.
- **Time** → `time.Duration`, `time.Time`. Field suffix `Millis`/`Seconds` if forced to int.
- **Type assertion** → comma-ok always.
- **Marshaled fields** → tag them.

## Style

- Soft 99-char lines.
- 2 import groups: stdlib, then others, blank line between.
- Package names: lowercase, singular. Never `util`/`common`/`shared`/`lib`.
- Group `const`/`var`/`type` declarations.
- Reduce nesting (early returns, `continue`).
- No `else` if both branches set the same variable.
- Prefix unexported globals with `_` (errors keep `err` prefix).
- Embedded fields at top of struct, separated by blank line. Never embed mutex.
- Field names always in struct init; omit zero-value fields.
- Raw string literals (\`...\`) to avoid escaping.
- Format strings outside `Printf`: `const`.

## Errors

- Return as-is when no context to add.
- `%w` when caller may match. `%v` to obfuscate.
- Drop `"failed to"`.
- Naming: `ErrFoo` (exported global), `errFoo` (unexported global), `FooError` (custom type).
- **Handle once**: never log AND return. Pick one.

## Concurrency

- `sync.Mutex` zero value is valid.
- `go.uber.org/atomic` for type-safe atomics.
- No goroutines in `init()`. Use a type with `Shutdown()`.
- `sync.WaitGroup` for many; `chan struct{}` for one.
- Copy slices/maps at trust boundaries.

## Performance (hot path)

- `strconv` over `fmt`.
- Hoist `[]byte("...")` from loops.
- Capacity hints: `make([]T, 0, n)`, `make(map[K]V, n)`.

## Testing

- Table tests with subtests; `tests` / `tt` / `give` / `want`.
- Split tables with branching pathways.
- `t.Fatal` not `panic`.
- Functional options for 3+ optional args.

## Avoid

Mutable globals · embedding in public structs · built-in names (`error`, `len`, `string`) · `init()` for I/O · panics in production · fire-and-forget goroutines.

## Lint

`./scripts/lint.sh` runs `golangci-lint` with `errcheck`, `goimports`, `revive`, `govet`, `staticcheck`.
