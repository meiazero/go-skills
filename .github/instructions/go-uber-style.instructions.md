---
applyTo: "**/*.go"
---

# Go (Uber Style) — applies to *.go

Adapted from the [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md). For full rules with Bad/Good examples, see the topic files at the repo root: `style.md`, `guidelines.md`, `errors.md`, `concurrency.md`, `performance.md`, `testing.md`.

## Defaults to apply automatically

- `nil` for empty slices (never `[]T{}`); `len(s) == 0` for emptiness checks.
- `var x T` for zero-value structs; `&T{Field: v}` for pointer init (never `new(T)`).
- Errors: `fmt.Errorf("context: %w", err)`. Never `"failed to"`. Naming: `ErrFoo` / `errFoo` / `FooError`.
- Goroutines: stop signal + wait mechanism, every time. No goroutines in `init()`.
- Mutex: non-pointer field, never embedded, `mu` by convention.
- Channel size: 0 or 1.
- Enum: `iota + 1`, unless 0 is meaningful.
- `os.Exit`/`log.Fatal` only in `main()`, once.
- `time.Duration`/`time.Time` always; field suffix `Millis`/`Seconds` if forced to int.
- Type assertion: comma-ok always.
- Struct fields marshaled: tag them.

## Style

- Soft 99-char lines.
- 2 import groups: stdlib, others.
- Package names: lowercase, singular, no `util`/`common`/`shared`/`lib`.
- Group declarations (`const`/`var`/`type`).
- Reduce nesting (early returns).
- Prefix unexported globals with `_` (except errors → `err`).
- Embedded fields at top of struct, blank line separator, never mutex.
- Field names in struct init; omit zero values; raw strings to avoid escaping.

## Errors — handle once

Don't log AND return. Either log + degrade, or wrap + return. Use `%w` to let callers match, `%v` to obfuscate.

## Concurrency

- `sync.Mutex` zero value valid; `go.uber.org/atomic` for type-safe atomics.
- Background workers expose `Shutdown()` that closes a stop chan and waits on a done chan.
- `sync.WaitGroup` for many, `chan struct{}` for one.
- Copy slices/maps at trust boundaries.

## Performance (hot path)

- `strconv` over `fmt` for primitives.
- Hoist `[]byte("...")` from loops.
- Capacity hints: `make([]T, 0, n)`, `make(map[K]V, n)`.

## Testing

- Table tests with subtests; `tests`/`tt`/`give`/`want` conventions.
- Split tables that accumulate branching pathways.
- `t.Fatal` not `panic`.
- Functional options for 3+ optional args: unexported `options` struct + `Option` interface with `apply(*options)`.

## Avoid

Mutable globals · embedding in public structs · built-in names (`error`, `len`, `string`) · `init()` for I/O · panics in production · fire-and-forget goroutines.
