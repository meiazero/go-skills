# Testing & API patterns

## Test Tables

Use table-driven tests with subtests when the **same logic** runs against multiple inputs:

```go
tests := []struct{
  give     string
  wantHost string
  wantPort string
}{
  {give: "192.0.2.0:8000", wantHost: "192.0.2.0", wantPort: "8000"},
  {give: "192.0.2.0:http", wantHost: "192.0.2.0", wantPort: "http"},
  {give: ":8000",          wantHost: "",          wantPort: "8000"},
  {give: "1:8",            wantHost: "1",         wantPort: "8"},
}

for _, tt := range tests {
  t.Run(tt.give, func(t *testing.T) {
    host, port, err := net.SplitHostPort(tt.give)
    require.NoError(t, err)
    assert.Equal(t, tt.wantHost, host)
    assert.Equal(t, tt.wantPort, port)
  })
}
```

Conventions:
- Slice variable: `tests`
- Loop variable: `tt`
- Input field prefix: `give`
- Expected field prefix: `want`

### Avoid Unnecessary Complexity in Table Tests

Don't use table tests when subtests need conditional/branching logic. Targets to aim for:

- Focus on the narrowest behavior unit
- Minimize "test depth" — chains of assertions where later ones depend on earlier
- All table fields used in all cases
- All test logic runs for every case

If a test has fields like `shouldCallX`, `expectCall`, multiple `if` branches for mock expectations, or `setupMocks func(...)` callbacks — split it into multiple `Test...` functions instead.

A single branching pathway like `shouldErr` for success vs. error is acceptable when the body is short.

```go
// Bad — too many branching pathways
tests := []struct {
  give          string
  want          string
  wantErr       error
  shouldCallX   bool
  shouldCallY   bool
  giveXResponse string
  giveXErr      error
  // ...
}{ /* ... */ }

// Good — split into separate tests
func TestShouldCallX(t *testing.T) { /* ... */ }
func TestShouldCallYAndFail(t *testing.T) { /* ... */ }
```

### Parallel Tests

When using `t.Parallel()` inside a table loop, the loop variable must be captured per-iteration — otherwise tests see the wrong (or shifting) `tt`:

```go
for _, tt := range tests {
  t.Run(tt.give, func(t *testing.T) {
    t.Parallel()
    // ...
  })
}
```

(In Go 1.22+ the per-iteration loop variable scope removes the historical `tt := tt` workaround, but the rule still holds: be explicit about parallelism.)

## Functional Options

For constructors with optional arguments — especially when there are 3+ args or you foresee adding more — use the functional options pattern instead of mandatory positional args.

```go
// Bad
func Open(addr string, cache bool, logger *zap.Logger) (*Connection, error) {
  // ...
}
// Caller must supply everything every time:
db.Open(addr, db.DefaultCache, zap.NewNop())

// Good
type Option interface { apply(*options) }

func WithCache(c bool) Option   { /* ... */ }
func WithLogger(l *zap.Logger) Option { /* ... */ }

func Open(addr string, opts ...Option) (*Connection, error) { /* ... */ }
// Caller supplies only what they need:
db.Open(addr)
db.Open(addr, db.WithLogger(log))
db.Open(addr, db.WithCache(false), db.WithLogger(log))
```

### Implementation pattern

Prefer an `Option` interface with an unexported method over closures. Interfaces allow options to:

- Be compared in tests/mocks
- Implement other interfaces (e.g., `fmt.Stringer` for readable output)

```go
type options struct {
  cache  bool
  logger *zap.Logger
}

type Option interface {
  apply(*options)
}

type cacheOption bool

func (c cacheOption) apply(opts *options) {
  opts.cache = bool(c)
}

func WithCache(c bool) Option {
  return cacheOption(c)
}

type loggerOption struct {
  Log *zap.Logger
}

func (l loggerOption) apply(opts *options) {
  opts.logger = l.Log
}

func WithLogger(log *zap.Logger) Option {
  return loggerOption{Log: log}
}

func Open(addr string, opts ...Option) (*Connection, error) {
  options := options{
    cache:  defaultCache,
    logger: zap.NewNop(),
  }
  for _, o := range opts {
    o.apply(&options)
  }
  // ...
}
```

## Don't panic in tests

`t.Fatal` and `t.FailNow` mark the test as failed and stop it. `panic` does neither cleanly:

```go
// Bad
f, err := os.CreateTemp("", "test")
if err != nil {
  panic("failed to set up test")
}

// Good
f, err := os.CreateTemp("", "test")
if err != nil {
  t.Fatal("failed to set up test")
}
```
