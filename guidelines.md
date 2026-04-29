# Guidelines

Core correctness rules. Read alongside style.md for any non-trivial Go work.

## Pointers to Interfaces

Almost never need a pointer to an interface. Pass interfaces as values — the underlying data can still be a pointer. To modify underlying data via interface methods, the underlying type must be a pointer.

## Verify Interface Compliance

For exported types implementing an interface as part of their API contract, or types in a collection implementing the same interface, verify compliance at compile time:

```go
type Handler struct { /* ... */ }

var _ http.Handler = (*Handler)(nil)

func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
  // ...
}
```

The right-hand side is the zero value of the asserted type: `nil` for pointers/slices/maps, empty struct for structs:

```go
var _ http.Handler = LogHandler{}
```

## Receivers and Interfaces

- Value-receiver methods can be called on pointers AND values
- Pointer-receiver methods can only be called on pointers or addressable values
- Map values are NOT addressable — pointer-receiver methods can't be called on them
- An interface can be satisfied by a pointer even if the method has a value receiver

```go
// Cannot do: sVals[1].Write("test") — map values aren't addressable
sPtrs := map[int]*S{1: {"A"}}
sPtrs[1].Write("test") // OK: pointers are addressable
```

## Zero-value Mutexes are Valid

`sync.Mutex` and `sync.RWMutex` zero values work — no need to allocate.

```go
// Bad
mu := new(sync.Mutex)

// Good
var mu sync.Mutex
```

If a struct uses a mutex and is used by pointer, make the mutex a non-pointer field. **Do not embed**, even on unexported types — embedding leaks `Lock`/`Unlock` to the public API.

```go
// Good
type SMap struct {
  mu sync.Mutex

  data map[string]string
}
```

## Copy Slices and Maps at Boundaries

Slices and maps share underlying memory. When **receiving** them as arguments and storing them, copy first — otherwise the caller can mutate your internal state.

```go
// Good
func (d *Driver) SetTrips(trips []Trip) {
  d.trips = make([]Trip, len(trips))
  copy(d.trips, trips)
}
```

When **returning** internal slices/maps, return a copy — otherwise callers can mutate state that may be mutex-protected:

```go
// Good
func (s *Stats) Snapshot() map[string]int {
  s.mu.Lock()
  defer s.mu.Unlock()

  result := make(map[string]int, len(s.counters))
  for k, v := range s.counters {
    result[k] = v
  }
  return result
}
```

## Defer to Clean Up

Use `defer` for resource cleanup (files, locks). Tiny overhead — only avoid in functions that must run in nanoseconds.

```go
// Good
p.Lock()
defer p.Unlock()

if p.count < 10 { return p.count }
p.count++
return p.count
```

## Channel Size is One or None

Channels are unbuffered (size 0) or size 1. Anything larger requires justification: how is the size determined? What blocks writers if it fills? What happens then?

```go
// Bad
c := make(chan int, 64)

// Good
c := make(chan int, 1)
c := make(chan int)
```

## Start Enums at One

Default value of `int` is 0. Start enum values at 1 unless 0 is the meaningful default:

```go
// Bad
const (
  Add Operation = iota   // = 0, ambiguous with zero value
  Subtract
  Multiply
)

// Good
const (
  Add Operation = iota + 1
  Subtract
  Multiply
)
```

Exception: when 0 is the desirable default behavior:

```go
const (
  LogToStdout LogOutput = iota // = 0, default
  LogToFile
  LogToRemote
)
```

## Use "time" to handle time

Time is hard. Always use the `"time"` package:

- **`time.Time`** for instants. Use `Before`, `After`, `Equal` to compare.
- **`time.Duration`** for periods. Don't pass `int` "milliseconds".

```go
// Bad
func poll(delay int) {
  time.Sleep(time.Duration(delay) * time.Millisecond)
}
poll(10) // seconds? milliseconds?

// Good
func poll(delay time.Duration) {
  time.Sleep(delay)
}
poll(10*time.Second)
```

For "next calendar day": `t.AddDate(0, 0, 1)`. For "24 hours later": `t.Add(24 * time.Hour)` — these are NOT the same (DST, leap seconds).

### External system interactions

Use `time.Time`/`time.Duration` directly when the system supports it (`flag`, `encoding/json` for `time.Time`, SQL `DATETIME`, YAML, etc.).

When you can't:
- Use `int`/`float64` and **include the unit in the field name**: `IntervalMillis int` (not `Interval int`)
- For timestamps, use `string` formatted as RFC 3339

## Errors

See [errors.md](errors.md).

## Handle Type Assertion Failures

Always use the comma-ok form:

```go
// Bad — panics if i is not a string
t := i.(string)

// Good
t, ok := i.(string)
if !ok {
  // handle gracefully
}
```

## Don't Panic

Production code must not panic. Return errors and let callers decide:

```go
// Good
func run(args []string) error {
  if len(args) == 0 {
    return errors.New("an argument is required")
  }
  return nil
}

func main() {
  if err := run(os.Args[1:]); err != nil {
    fmt.Fprintln(os.Stderr, err)
    os.Exit(1)
  }
}
```

`panic`/`recover` is **not** an error-handling strategy. Only panic for irrecoverable states (nil deref) or **program initialization** failures:

```go
var _statusTemplate = template.Must(template.New("name").Parse(_statusHTML))
```

In tests, prefer `t.Fatal`/`t.FailNow` over `panic`.

## Use go.uber.org/atomic

`sync/atomic` operates on raw types — easy to forget the atomic op and read non-atomically. `go.uber.org/atomic` adds type safety and provides `atomic.Bool`.

```go
// Bad
type foo struct {
  running int32 // atomic
}
func (f *foo) isRunning() bool { return f.running == 1 } // race!

// Good
type foo struct {
  running atomic.Bool
}
func (f *foo) isRunning() bool { return f.running.Load() }
```

## Avoid Mutable Globals

Use dependency injection instead of mutable package-level vars (including function pointers):

```go
// Bad
var _timeNow = time.Now

func sign(msg string) string {
  return signWithTime(msg, _timeNow())
}

// Good
type signer struct {
  now func() time.Time
}

func newSigner() *signer {
  return &signer{now: time.Now}
}

func (s *signer) Sign(msg string) string {
  return signWithTime(msg, s.now())
}
```

## Avoid Embedding Types in Public Structs

Embedding leaks implementation details, inhibits evolution, and obscures docs. For a public type backed by an `AbstractList`, write delegate methods rather than embedding:

```go
// Bad
type ConcreteList struct {
  *AbstractList
}

// Good
type ConcreteList struct {
  list *AbstractList
}

func (l *ConcreteList) Add(e Entity)    { l.list.Add(e) }
func (l *ConcreteList) Remove(e Entity) { l.list.Remove(e) }
```

Adding methods to an embedded interface is a breaking change. Removing methods from an embedded struct is a breaking change. Removing or replacing the embedded type is a breaking change.

## Avoid Using Built-In Names

Don't use predeclared identifiers (`error`, `string`, `int`, `len`, `nil`, etc.) as names. Causes shadowing or grep-ambiguity:

```go
// Bad
type Foo struct {
  error  error
  string string
}

// Good
type Foo struct {
  err error
  str string
}
```

`go vet` flags many cases.

## Avoid init()

Avoid `init()`. When unavoidable, it must:

1. Be deterministic (no env, no working dir, no flags)
2. Avoid depending on other `init()` order/side-effects
3. Avoid global/environment state
4. Avoid I/O (filesystem, network, syscalls)

Code that can't satisfy these belongs as a helper called from `main()`. Libraries especially must not do "init magic".

```go
// Bad — init does I/O
var _config Config
func init() {
  cwd, _ := os.Getwd()
  raw, _ := os.ReadFile(path.Join(cwd, "config", "config.yaml"))
  yaml.Unmarshal(raw, &_config)
}

// Good — explicit function called from main
func loadConfig() Config { /* ... */ }
```

`init()` is OK for: complex non-assignable expressions, pluggable hooks (`database/sql` dialects), deterministic precomputation.

## Exit in Main

Call `os.Exit` or `log.Fatal*` **only in `main()`**. Other functions return errors.

Reasons:
- Non-obvious control flow (any function can kill the program)
- Hard to test (exits the test process)
- Skipped `defer` cleanup

### Exit Once

Prefer **at most one** `os.Exit`/`log.Fatal` in `main()`. Push logic into a separate `run()`:

```go
func main() {
  if err := run(); err != nil {
    log.Fatal(err)
  }
}

func run() error {
  args := os.Args[1:]
  if len(args) != 1 {
    return errors.New("missing file")
  }
  // ...
  return nil
}
```

Variations: return exit code instead of error, accept `os.Args` directly, etc. — the rule is one exit point.

## Use field tags in marshaled structs

Annotate struct fields marshaled to JSON/YAML/etc. with the relevant tag. The serialized form is a contract; tags make field names explicit and refactor-safe:

```go
// Bad
type Stock struct {
  Price int
  Name  string
}

// Good
type Stock struct {
  Price int    `json:"price"`
  Name  string `json:"name"`
}
```

## Don't fire-and-forget goroutines

See [concurrency.md](concurrency.md).
