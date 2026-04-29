# Repository custom instructions for GitHub Copilot

> Applies to all Go code in this repository. Adapted from the [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md).

When suggesting Go code, follow these rules. For any non-trivial Go work, refer to the topic markdown files at the repo root for the full ruleset with Bad/Good examples: `style.md`, `guidelines.md`, `errors.md`, `concurrency.md`, `performance.md`, `testing.md`.

## Critical defaults

- Return `nil` for empty slices, never `[]T{}`. Check emptiness with `len(s) == 0`.
- Declare zero-value structs as `var x T`, not `T{}`.
- Initialize pointer structs with `&T{Name: "x"}`, never `new(T)`.
- Wrap errors with `fmt.Errorf("context: %w", err)` — drop `"failed to"`.
- Goroutines must have a stop signal AND a way to wait for exit.
- Mutexes: non-pointer field, never embedded, named `mu`.
- Channels: unbuffered or size 1. Larger sizes need justification.
- Enums: start at `iota + 1` unless 0 is the default.
- `os.Exit` / `log.Fatal` only in `main()`, ideally once via a `run()` helper.
- Always use `time.Duration` and `time.Time` for time. If forced to int (JSON), suffix the field with the unit: `IntervalMillis`.
- Always use comma-ok form for type assertions: `t, ok := i.(string)`.

## Style

- Line length: soft 99 chars.
- Two import groups: stdlib, then everything else, blank line between.
- Package names: lowercase, singular, never `util`/`common`/`shared`/`lib`.
- Reduce nesting: handle special cases first, return early, continue loops.
- No `else` when both branches assign the same variable.
- Embedded struct fields go at the top, separated from regular fields by a blank line. Never embed mutexes.
- Use field names for struct init; omit zero-value fields unless they add meaning.
- Use raw string literals (\`...\`) to avoid escaping.
- Format strings outside `Printf` must be `const`.

## Errors

- Return as-is when no context to add.
- Wrap with `%w` when the caller may want to match the underlying error.
- Wrap with `%v` to deliberately obfuscate.
- Naming: exported global error → `ErrFoo`. Unexported global error → `errFoo` (no underscore prefix). Custom error type → `FooError`.
- **Handle each error once**: don't log AND return — pick one. Either log and gracefully degrade, or wrap and return.

## Concurrency

- `sync.Mutex` zero value is valid — never `new(sync.Mutex)`.
- Prefer `go.uber.org/atomic` over raw `sync/atomic` for type safety.
- No goroutines in `init()`. Expose a `Worker` type with a `Shutdown()` method that signals stop and waits.
- Use `sync.WaitGroup` for multiple goroutines, `chan struct{}` for one.
- Copy slices/maps at trust boundaries (when receiving for storage, or returning internal state).

## Performance (hot path only)

- Use `strconv.Itoa` over `fmt.Sprint` for primitives.
- Hoist `[]byte("literal")` constants out of loops.
- Provide capacity hints: `make(map[K]V, len(src))`, `make([]T, 0, expected)`.

## Testing

- Use table-driven tests with subtests for repeated logic. Conventions: slice `tests`, loop var `tt`, field prefixes `give`/`want`.
- Don't accumulate branching pathways (`shouldCallX`, `setupMocks`) in one table — split into separate tests.
- Use `t.Fatal` or `t.FailNow`, never `panic`.
- For constructors with 3+ optional args, use the functional options pattern with an unexported `options` struct and an `Option` interface.

## Avoid

- Mutable package-level globals (use dependency injection).
- Embedding types in public structs (prefer named fields with delegate methods).
- Built-in identifiers as names (`error`, `string`, `len`, etc.).
- `init()` for I/O, env access, or non-deterministic work.
- Panics in production code (only OK at program init or for irrecoverable states).
- Fire-and-forget goroutines.
