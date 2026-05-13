# Errors

How to declare, wrap, name, and handle errors.

## Error Types

Decision matrix:

| Caller matches? | Message | Use |
|---|---|---|
| No | static | `errors.New` |
| No | dynamic | `fmt.Errorf` |
| Yes | static | top-level `var` with `errors.New` |
| Yes | dynamic | custom `error` type |

Questions to ask:
- Does the caller need to **match** the error (use `errors.Is`/`errors.As`)?
- Is the message **static** or does it need contextual data?
- Are we just **propagating** an upstream error? See Error Wrapping below.

```go
// No matching, static
func Open() error {
  return errors.New("could not open")
}

// Matching, static — top-level var
var ErrCouldNotOpen = errors.New("could not open")

func Open() error {
  return ErrCouldNotOpen
}

// No matching, dynamic
func Open(file string) error {
  return fmt.Errorf("file %q not found", file)
}

// Matching, dynamic — custom type
type NotFoundError struct {
  File string
}

func (e *NotFoundError) Error() string {
  return fmt.Sprintf("file %q not found", e.File)
}

func Open(file string) error {
  return &NotFoundError{File: file}
}

// Caller side
if err := foo.Open("x.txt"); err != nil {
  var notFound *NotFoundError
  if errors.As(err, &notFound) {
    // handle
  }
}
```

Exporting an error variable or type makes it part of your **public API** — commit to it.

## Error Wrapping

Three propagation choices:

1. **Return as-is** — when you have nothing to add and the upstream message is sufficient.
2. **Wrap with `%w`** — caller can match the underlying error via `errors.Is`/`errors.As`. Default for most wrapping. If you wrap a known `var` or type, document and test it as part of the contract.
3. **Wrap with `%v`** — obfuscates the underlying error. Caller can't match it. You can switch to `%w` later if needed.

### Don't say "failed to"

Context piles up. `"failed to"` repeats at every level. Be terse:

```go
// Bad
return fmt.Errorf("failed to create new store: %w", err)
// → "failed to x: failed to y: failed to create new store: the error"

// Good
return fmt.Errorf("new store: %w", err)
// → "x: y: new store: the error"
```

When the error reaches a logger or external system, the consumer adds the `err`/`Failed` indicator there.

## Error Naming

**Global error variables**: prefix `Err` (exported) or `err` (unexported). This **supersedes** the underscore prefix rule for unexported globals.

```go
var (
  // Exported — part of public API, callers match with errors.Is
  ErrBrokenLink   = errors.New("link is broken")
  ErrCouldNotOpen = errors.New("could not open")

  // Unexported — internal, no underscore needed
  errNotFound = errors.New("not found")
)
```

**Custom error types**: suffix `Error`.

```go
// Exported
type NotFoundError struct {
  File string
}
func (e *NotFoundError) Error() string { /* ... */ }

// Unexported
type resolveError struct {
  Path string
}
func (e *resolveError) Error() string { /* ... */ }
```

## Handle Errors Once

When you receive an error, handle it **once** — don't log AND return.

```go
// Bad — caller will likely log too, doubling noise
u, err := getUser(id)
if err != nil {
  log.Printf("Could not get user %q: %v", id, err)
  return err
}

// Good — wrap and return; callers decide what to do
u, err := getUser(id)
if err != nil {
  return fmt.Errorf("get user %q: %w", id, err)
}
```

Handling options (pick one per error):

- **Match and branch** with `errors.Is`/`errors.As`, handle each case differently
- **Log and degrade** if the operation isn't strictly required
- **Return a domain-specific error** that callers understand
- **Return wrapped or verbatim** for callers higher up to handle

Examples:

```go
// Good: log and degrade — non-critical operation
if err := emitMetrics(); err != nil {
  log.Printf("Could not emit metrics: %v", err)
}

// Good: match and degrade for known error, wrap for everything else
tz, err := getUserTimeZone(id)
if err != nil {
  if errors.Is(err, ErrUserNotFound) {
    tz = time.UTC // default
  } else {
    return fmt.Errorf("get user %q: %w", id, err)
  }
}
```
