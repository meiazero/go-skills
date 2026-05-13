# Output examples

Reference these when formatting review comments. Each violation = one block: location, rule name, one-sentence issue, unified diff fix.

## Reduce nesting (warning)

```
service/handler.go:42-50 — Rule: Reduce Nesting
Issue: error branch buried under nested if/else hides the happy path.
Fix:
```diff
- for _, v := range data {
-   if v.F1 == 1 {
-     v = process(v)
-     if err := v.Call(); err == nil {
-       v.Send()
-     } else {
-       return err
-     }
-   } else {
-     log.Printf("Invalid v: %v", v)
-   }
- }
+ for _, v := range data {
+   if v.F1 != 1 {
+     log.Printf("Invalid v: %v", v)
+     continue
+   }
+   v = process(v)
+   if err := v.Call(); err != nil {
+     return err
+   }
+   v.Send()
+ }
```
```

## Error wrapping — "failed to" (warning)

```
internal/store/db.go:88 — Rule: Don't say "failed to"
Issue: `"failed to"` prefix stacks meaningless context at every wrap layer.
Fix:
```diff
- return fmt.Errorf("failed to create new store: %w", err)
+ return fmt.Errorf("new store: %w", err)
```
```

## Handle errors once (warning)

```
internal/user/svc.go:120-124 — Rule: Handle Errors Once
Issue: logs the error and also returns it — caller will log again, doubling noise.
Fix:
```diff
- u, err := getUser(id)
- if err != nil {
-   log.Printf("Could not get user %q: %v", id, err)
-   return err
- }
+ u, err := getUser(id)
+ if err != nil {
+   return fmt.Errorf("get user %q: %w", id, err)
+ }
```
```

## Fire-and-forget goroutine (critical)

```
worker/flush.go:60-66 — Rule: Don't fire-and-forget goroutines
Issue: goroutine has no stop signal and no exit-wait — leaks on shutdown.
Fix:
```diff
- go func() {
-   for {
-     flush()
-     time.Sleep(delay)
-   }
- }()
+ stop := make(chan struct{})
+ done := make(chan struct{})
+ go func() {
+   defer close(done)
+   ticker := time.NewTicker(delay)
+   defer ticker.Stop()
+   for {
+     select {
+     case <-ticker.C:
+       flush()
+     case <-stop:
+       return
+     }
+   }
+ }()
```
```

## Type assertion without comma-ok (critical)

```
api/decode.go:31 — Rule: Handle Type Assertion Failures
Issue: bare `.(string)` panics when `i` is not a string.
Fix:
```diff
- name := i.(string)
+ name, ok := i.(string)
+ if !ok {
+   return fmt.Errorf("name: want string, got %T", i)
+ }
```
```

## Empty slice return (nit)

```
internal/list/filter.go:18 — Rule: nil is a valid slice
Issue: returns `[]int{}`; prefer `nil` for empty slices.
Fix:
```diff
- if x == "" {
-   return []int{}
- }
+ if x == "" {
+   return nil
+ }
```
```

## Pointer struct init with new() (nit)

```
internal/user/build.go:12 — Rule: Initializing Struct References
Issue: `new(T)` then setting fields one by one; use struct literal.
Fix:
```diff
- u := new(User)
- u.Name = "bar"
+ u := &User{Name: "bar"}
```
```

## Mutex embedded (critical — leaks Lock/Unlock to public API)

```
cache/store.go:8-11 — Rule: Embedding in Structs
Issue: embedded `sync.Mutex` exposes `Lock`/`Unlock` on the public type.
Fix:
```diff
  type Store struct {
-   sync.Mutex
-   data map[string]string
+   mu sync.Mutex
+
+   data map[string]string
  }
```
```

## Hot-path slice capacity (warning, only on hot path)

```
internal/pipeline/batch.go:55-58 — Rule: Slice Capacity
Issue: hot-path loop appends `size` elements to a zero-capacity slice — reallocates repeatedly.
Fix:
```diff
- data := make([]int, 0)
- for k := 0; k < size; k++ {
-   data = append(data, k)
- }
+ data := make([]int, 0, size)
+ for k := 0; k < size; k++ {
+   data = append(data, k)
+ }
```
```

## End-of-review summary

After all blocks, append one line:

```
Review: 2 critical, 5 warning, 3 nit. internal/user/*.go
```

If nothing was found:

```
No Uber Go style violations found in internal/user/*.go.
```
