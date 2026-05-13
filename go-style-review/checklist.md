# Checklist — Uber Go Style violations

Compact scan table. Each row: pattern to spot → rule name → fix direction. Open the matching topic file for the verbatim Bad/Good example when you need to show one.

## Style ([style.md](style.md))

| Look for | Rule | Fix |
|---|---|---|
| Line > 99 chars | Avoid overly long lines | Wrap before 99 |
| Adjacent single `const a = 1` / `const b = 2` | Group Similar Declarations | Wrap in `const ( ... )` |
| Imports not split into stdlib + others | Import Group Ordering | Two groups, blank line between |
| Package named `util` / `common` / `shared` / `lib` / plural | Package Names | Rename: lowercase, singular, specific |
| Underscores in non-test function names | Function Names | MixedCaps |
| Import alias matches the last path element | Import Aliasing | Drop the alias |
| Deep nesting (if/else inside for, multiple levels) | Reduce Nesting | Early return, `continue` |
| `else` branch sets the same variable as `if` | Unnecessary Else | Default value + override in `if` |
| `var _s string = F()` with redundant explicit type | Top-level Variable Declarations | Drop the type unless mismatched |
| Top-level unexported `var x` / `const x` (non-error) | Prefix Unexported Globals with _ | Prefix `_` |
| Embedded type mixed with regular fields | Embedding in Structs | Embedded fields at top, blank line, then regular |
| `sync.Mutex` embedded in a struct | Embedding in Structs | Named field `mu sync.Mutex` |
| `s == nil` to test slice emptiness | nil is a valid slice | `len(s) == 0` |
| Returning `[]T{}` for an empty slice | nil is a valid slice | Return `nil` |
| `err := X(); if err != nil` where err is unused after | Reduce Scope of Variables | `if err := X(); err != nil` |
| Naked positional bool/int args (`f(true, 0)`) | Avoid Naked Parameters | Inline comment or custom enum type |
| String literal with `\"` escaping | Use Raw String Literals to Avoid Escaping | Use `` ` ` `` |
| Struct init by position (`User{"a", "b"}`) | Use Field Names | Specify field names |
| Zero-value fields explicitly set in struct literal | Omit Zero Value Fields | Drop them (unless meaningful — e.g., test tables) |
| `user := User{}` zero-value struct | Use `var` for Zero Value Structs | `var user User` |
| `new(T)` for pointer struct init | Initializing Struct References | `&T{...}` |
| `map[K]V{}` for empty map about to be populated | Initializing Maps | `make(map[K]V)` |
| Format string declared as `var` outside the call site | Format Strings outside Printf | `const msg = "..."` |
| Custom Printf-like function whose name doesn't end in `f` | Naming Printf-style Functions | End the name in `f` |

## Guidelines ([guidelines.md](guidelines.md))

| Look for | Rule | Fix |
|---|---|---|
| `*SomeInterface` parameter or return | Pointers to Interfaces | Pass interface as value |
| Exported type implements interface, no compile-time assertion | Verify Interface Compliance | `var _ I = (*T)(nil)` |
| Pointer-receiver method called on a map value | Receivers and Interfaces | Store pointers in map, or use value receiver |
| `mu := new(sync.Mutex)` | Zero-value Mutexes are Valid | `var mu sync.Mutex` |
| Receiving a slice/map and storing the reference | Copy Slices and Maps at Boundaries | `copy()` for slices, rebuild map |
| Returning internal slice/map (esp. under mutex) | Copy Slices and Maps at Boundaries | Return a copy |
| Missing `defer` for cleanup (file close, lock release) | Defer to Clean Up | Add `defer` |
| `make(chan T, N)` with N > 1, no justification | Channel Size is One or None | Reduce to 0 or 1, or justify the size |
| `iota`-based enum starting at 0 (no meaning for 0) | Start Enums at One | `iota + 1` |
| `int` parameter conveying milliseconds/seconds | Use "time" to handle time | `time.Duration` (or `IntervalMillis int` if forced by JSON) |
| `t := i.(string)` without comma-ok | Handle Type Assertion Failures | `t, ok := i.(string)` |
| `panic()` outside `main()` init / irrecoverable state | Don't Panic | Return error |
| Raw `sync/atomic` on a struct field (`int32` flag) | Use go.uber.org/atomic | `atomic.Bool` etc. |
| Mutable package-level `var` (including `var _timeNow = time.Now`) | Avoid Mutable Globals | Inject via struct field |
| Embedded type in a public struct | Avoid Embedding Types in Public Structs | Delegate methods through a named field |
| Field named `error`, `string`, `int`, `len`, `nil`, ... | Avoid Using Built-In Names | Rename (`err`, `str`, ...) |
| `init()` that does I/O, reads env, parses flags | Avoid init() | Move to an explicit function called from `main()` |
| `os.Exit` / `log.Fatal*` outside `main()` | Exit in Main | Return errors; exit only in `main()` |
| Multiple `os.Exit` / `log.Fatal` calls in `main()` | Exit Once | Push logic into `run() error`, exit once |
| Marshaled struct field without serialization tag | Use field tags in marshaled structs | Add `json:"..."` / `yaml:"..."` etc. |

## Errors ([errors.md](errors.md))

| Look for | Rule | Fix |
|---|---|---|
| `"failed to ..."` in `fmt.Errorf` | Don't say "failed to" | Drop the prefix; let context show it's an error |
| `errors.New("X")` inline for a matchable static error | Error Types | Move to top-level `var ErrX = errors.New(...)` |
| Log AND return the same error | Handle Errors Once | Pick one — usually wrap with `%w` and return |
| `%v` wrap where caller may need `errors.Is` / `errors.As` | Error Wrapping | Use `%w` |
| Exported error variable not prefixed `Err` | Error Naming | Rename to `ErrXxx` |
| Unexported global error prefixed `_err` | Error Naming | Use `errXxx` (no underscore) |
| Custom error type without `Error` suffix | Error Naming | Suffix the type name with `Error` |

## Concurrency ([concurrency.md](concurrency.md))

| Look for | Rule | Fix |
|---|---|---|
| `go func() {...}()` without a stop signal AND exit-wait | Don't fire-and-forget goroutines | Stop channel + done channel / WaitGroup |
| Goroutine spawned inside `init()` | No goroutines in init() | Move to constructor; expose `Shutdown()` |
| Channel buffer > 1 with no justification | Channel Size is One or None | Reduce to 0 or 1 |
| Raw `sync/atomic` ops on struct field, non-atomic reads elsewhere | Use go.uber.org/atomic | `atomic.Bool` / typed wrappers |
| Mutex embedded in struct (also a style issue) | Zero-value Mutexes are Valid | Field `mu sync.Mutex`, never embed |

## Performance — hot path only ([performance.md](performance.md))

| Look for | Rule | Fix |
|---|---|---|
| `fmt.Sprint(n)` for int→string inside a loop | Prefer strconv over fmt | `strconv.Itoa(n)` |
| `[]byte("literal")` repeated inside a loop | Avoid repeated string-to-byte conversions | Hoist outside the loop |
| `make([]T, 0)` then `append` with known final size | Prefer Specifying Container Capacity | `make([]T, 0, size)` |
| `make(map[K]V)` with known final size | Map Capacity Hints | `make(map[K]V, hint)` |

## Testing ([testing.md](testing.md))

| Look for | Rule | Fix |
|---|---|---|
| Same logic repeated against multiple inputs without a table | Test Tables | Convert to table-driven with subtests |
| Table tests with `shouldCallX` / `setupMocks` branching fields | Avoid Unnecessary Complexity in Table Tests | Split into separate `Test*` functions |
| `panic()` in test setup | Don't panic in tests | `t.Fatal` / `t.FailNow` |
| Constructor with 3+ optional positional args | Functional Options | `WithX(...) Option` pattern |
| `t.Parallel()` inside a table loop without per-iteration capture (pre-1.22 code) | Parallel Tests | Capture `tt` per iteration |
