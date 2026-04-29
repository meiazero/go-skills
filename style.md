# Style

Formatting, naming, declarations, and structural rules.

## Avoid overly long lines

Soft limit: **99 characters**. Wrap before that; not a hard limit.

## Be Consistent

Above all else, be consistent across a codebase. Apply style changes at the package level or larger, never sub-package — mixed styles within one package cause cognitive overhead.

## Group Similar Declarations

Group related `import`, `const`, `var`, `type` declarations. Don't group unrelated ones.

```go
// Bad
const a = 1
const b = 2

// Good
const (
  a = 1
  b = 2
)
```

Adjacent variable declarations inside functions should also be grouped — even if unrelated:

```go
// Good
func (c *client) request() {
  var (
    caller  = c.name
    format  = "json"
    timeout = 5*time.Second
    err     error
  )
}
```

## Import Group Ordering

Two groups: stdlib first, then everything else (separated by blank line). This matches `goimports` default.

```go
import (
  "fmt"
  "os"

  "go.uber.org/atomic"
  "golang.org/x/sync/errgroup"
)
```

## Package Names

- All lowercase, no caps or underscores
- Short, succinct
- Singular (`net/url`, not `net/urls`)
- Not `common`, `util`, `shared`, `lib`
- Should not need renaming via named imports at most call sites

## Function Names

MixedCaps. Test functions may use underscores for grouping: `TestMyFunction_WhatIsBeingTested`.

## Import Aliasing

Required only when the package name doesn't match the last path element:

```go
import (
  "net/http"

  client "example.com/client-go"
  trace "example.com/trace/v2"
)
```

Otherwise avoid aliases unless there is a direct name conflict.

## Function Grouping and Ordering

- Sort functions in rough call order
- Group functions in a file by receiver
- Exported functions appear first, after `struct`/`const`/`var` definitions
- `newXYZ()`/`NewXYZ()` appears after the type but before the rest of its methods
- Plain utility functions go at the end of the file

## Reduce Nesting

Handle errors/special conditions first, return early, continue the loop. Reduce code nested multiple levels.

```go
// Bad
for _, v := range data {
  if v.F1 == 1 {
    v = process(v)
    if err := v.Call(); err == nil {
      v.Send()
    } else {
      return err
    }
  } else {
    log.Printf("Invalid v: %v", v)
  }
}

// Good
for _, v := range data {
  if v.F1 != 1 {
    log.Printf("Invalid v: %v", v)
    continue
  }
  v = process(v)
  if err := v.Call(); err != nil {
    return err
  }
  v.Send()
}
```

## Unnecessary Else

If a variable is set in both branches, replace with one `if`:

```go
// Bad
var a int
if b { a = 100 } else { a = 10 }

// Good
a := 10
if b { a = 100 }
```

## Top-level Variable Declarations

Use `var`. Don't specify type unless the expression's type doesn't match the desired type.

```go
// Bad: type is redundant
var _s string = F()

// Good
var _s = F()

// Good: F returns myError, but we want error
var _e error = F()
```

## Prefix Unexported Globals with _

Unexported top-level `var`s and `const`s get `_` prefix. Avoids accidentally shadowing them inside functions.

```go
const (
  _defaultPort = 8080
  _defaultUser = "user"
)
```

**Exception**: Unexported error values use `err` prefix (no underscore). See errors.md.

## Embedding in Structs

Embedded types go at the **top** of the field list, separated from regular fields by a blank line:

```go
// Good
type Client struct {
  http.Client

  version int
}
```

Embedding **must** provide tangible benefit. Do not embed if it:

- Is purely cosmetic
- Affects the outer type's zero-value usefulness
- Exposes unrelated fields/methods
- Exposes unexported types
- Affects copy semantics
- Allows users to control internals

**Mutexes are never embedded**, even on unexported types.

If the answer to "would all of these inner methods/fields be added directly to the outer type" is "some" or "no", use a field instead of embedding.

```go
// Bad
type Client struct {
  sync.Mutex
  sync.WaitGroup
  bytes.Buffer
  url.URL
}

// Good
type Client struct {
  mtx sync.Mutex
  wg  sync.WaitGroup
  buf bytes.Buffer
  url url.URL
}
```

## Local Variable Declarations

Use `:=` when setting to an explicit value. Use `var` when the zero value is clearer (e.g., empty slices):

```go
// Good
s := "foo"

// Good: nil slice via var, instead of []int{}
var filtered []int
for _, v := range list {
  if v > 10 {
    filtered = append(filtered, v)
  }
}
```

## nil is a valid slice

- Return `nil`, not `[]T{}`, for empty slices
- Test emptiness with `len(s) == 0`, never `s == nil`
- A `var s []T` slice is usable with `append` immediately

```go
// Bad
if x == "" { return []int{} }
func isEmpty(s []string) bool { return s == nil }

// Good
if x == "" { return nil }
func isEmpty(s []string) bool { return len(s) == 0 }
```

Note: a nil slice is not equivalent to an allocated zero-length slice when serialized — they may marshal differently.

## Reduce Scope of Variables

Where possible, reduce variable/constant scope. Don't if it conflicts with Reduce Nesting.

```go
// Bad
err := os.WriteFile(name, data, 0644)
if err != nil { return err }

// Good
if err := os.WriteFile(name, data, 0644); err != nil {
  return err
}
```

If you need the result outside the `if`, don't try to scope it down:

```go
// Good
data, err := os.ReadFile(name)
if err != nil { return err }
if err := cfg.Decode(data); err != nil { return err }
```

Constants don't need to be global unless used in multiple functions/files or part of an external contract — declare them inside the function.

## Avoid Naked Parameters

Comment unclear positional bool/int args at the call site, or use custom types:

```go
// OK
printInfo("foo", true /* isLocal */, true /* done */)

// Better: custom types
type Region int
const (
  UnknownRegion Region = iota
  Local
)
```

## Use Raw String Literals to Avoid Escaping

```go
// Bad
wantError := "unknown name:\"test\""

// Good
wantError := `unknown error:"test"`
```

## Initializing Structs

### Use Field Names

Always specify field names (enforced by `go vet`):

```go
// Bad
k := User{"John", "Doe", true}

// Good
k := User{
  FirstName: "John",
  LastName:  "Doe",
  Admin:     true,
}
```

**Exception**: test tables with ≤ 3 fields may omit names.

### Omit Zero Value Fields

Omit fields that have zero values unless they provide meaningful context:

```go
// Bad
user := User{
  FirstName:  "John",
  LastName:   "Doe",
  MiddleName: "",
  Admin:      false,
}

// Good
user := User{
  FirstName: "John",
  LastName:  "Doe",
}
```

Include zero values when names give meaning (e.g., test tables with `give`/`want`).

### Use `var` for Zero Value Structs

```go
// Bad
user := User{}

// Good
var user User
```

### Initializing Struct References

Use `&T{}`, not `new(T)`:

```go
// Bad
sptr := new(T)
sptr.Name = "bar"

// Good
sptr := &T{Name: "bar"}
```

## Initializing Maps

- Empty/programmatically-populated maps: `make(map[T1]T2)` (not `map[T1]T2{}`)
- Provide capacity hint when size is known (see performance.md)
- Fixed-content maps: use a literal

```go
// Good (empty, will be populated)
m1 := make(map[T1]T2)

// Good (fixed content)
m := map[T1]T2{
  k1: v1,
  k2: v2,
}
```

## Format Strings outside Printf

Format strings declared outside the call site must be `const` so `go vet` can analyze them:

```go
// Bad
msg := "unexpected values %v, %v\n"

// Good
const msg = "unexpected values %v, %v\n"
fmt.Printf(msg, 1, 2)
```

## Naming Printf-style Functions

Use predefined names (`Printf`, `Errorf`, etc.) when possible — `go vet` checks them by default. Custom names must end in `f` (`Wrapf`, not `Wrap`), then registered:

```shell
go vet -printfuncs=wrapf,statusf
```
