# Uber Go Style — Agent Instructions

> Applies to all Go code in this repository. Source: <https://github.com/uber-go/guide/blob/master/style.md>

## Scope

Apply these rules whenever you write, refactor, or review Go code (`.go` files, `go.mod` present). For any non-trivial Go work, **read the relevant topic file first** — they contain the verbatim rule set with Bad/Good code examples.

| Topic file | Read when |
|---|---|
| [style.md](style.md) | Naming, imports, struct/map init, line length, variable scope, raw strings, embedding |
| [guidelines.md](guidelines.md) | Interfaces, receivers, enums, time handling, type assertions, panics, globals, `init()`, `os.Exit` |
| [errors.md](errors.md) | Returning, wrapping (`%w` vs `%v`), naming (`Err*`/`*Error`), handle-once rule |
| [concurrency.md](concurrency.md) | Mutexes, channels, goroutine lifetimes, `sync.WaitGroup`, atomics |
| [performance.md](performance.md) | `strconv` over `fmt`, byte conversion, slice/map capacity hints |
| [testing.md](testing.md) | Test tables, parallel tests, functional options pattern |

## Decision shortcuts (apply always)

- **Empty slice?** Return `nil`, not `[]T{}`. Test emptiness with `len(s) == 0`.
- **Zero-value struct?** `var x T`, not `T{}`.
- **Pointer struct init?** `&T{Name: "x"}`, not `new(T)`.
- **Wrapping error?** `fmt.Errorf("get user %q: %w", id, err)` — never `"failed to"`.
- **Goroutine?** Must have a stop signal AND a wait mechanism.
- **Mutex?** Non-pointer field, never embedded, name it `mu`.
- **Channel?** Size 0 (unbuffered) or 1. Larger needs justification.
- **Enum at iota?** `iota + 1` unless 0 is meaningful default.
- **`os.Exit` / `log.Fatal`?** Only in `main()`, ideally exactly once.
- **Top-level unexported `var`/`const`?** Prefix `_` (errors keep `err` prefix instead).
- **Time durations?** `time.Duration`, never `int` "milliseconds". If forced to int (JSON), name field `IntervalMillis`.
- **Type assertion?** Always comma-ok form: `t, ok := i.(string)`.
- **Struct field marshaled?** Annotate with the tag (`json`, `yaml`, etc.).

## Style essentials

- Line length: soft 99 chars
- Imports: two groups — stdlib, then everything else (blank line between)
- Package names: lowercase, singular, no `util`/`common`/`shared`/`lib`
- Group similar declarations (`const`, `var`, `type`) into blocks
- Reduce nesting via early return / `continue`
- No `else` if both branches set the same variable
- Embedded types go at the **top** of struct fields, then a blank line
- Mutexes are NEVER embedded
- Use field names when initializing structs (omit zero-value fields)
- Use raw string literals (\`...\`) to avoid escaping

## Errors

- Return as-is when adding nothing
- Wrap with `%w` when caller may need to match (`errors.Is`/`errors.As`)
- Wrap with `%v` to obfuscate the underlying cause
- Drop `"failed to"` from messages — context already shows it's an error
- Naming: exported global → `ErrXxx`, unexported global → `errXxx` (not `_errXxx`), custom type → `XxxError`
- **Handle once**: don't `log + return`. Either log AND degrade, OR wrap AND return — never both.

## Concurrency

- Zero-value `sync.Mutex` is valid — never `new(sync.Mutex)`
- Use `go.uber.org/atomic` for type-safe atomics (especially `atomic.Bool`)
- Every goroutine: predictable stop AND a way to wait for exit
- No goroutines in `init()` — expose a `Worker` with `Shutdown()` instead
- Use `sync.WaitGroup` for many goroutines, `chan struct{}` for one
- Copy slices/maps at trust boundaries — receivers and returners

## Performance (hot path only)

- `strconv.Itoa` instead of `fmt.Sprint` for primitives
- Hoist `[]byte("literal")` out of loops
- `make(map[K]V, hint)` and `make([]T, 0, cap)` when size is known

## Testing

- Use table-driven tests with subtests when same logic runs against multiple inputs
- Conventions: slice `tests`, loop var `tt`, prefixes `give`/`want`
- Don't pile up branching pathways (`shouldCallX`, `setupMocks`) in one table — split into separate tests
- Use `t.Fatal` / `t.FailNow`, never `panic` in tests
- Use functional options pattern (`type Option interface{...}`, `WithX(...) Option`) for constructors with 3+ optional args

## Linting

Run `./scripts/lint.sh`. Recommended linter set: `errcheck`, `goimports`, `revive`, `govet`, `staticcheck`.

---

When in doubt, **read the relevant topic file** linked above. The full Bad/Good code examples are there.
