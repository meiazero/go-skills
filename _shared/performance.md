# Performance

Apply only to the **hot path**. Don't pessimize cold code for ergonomic loss.

## Prefer strconv over fmt

For primitive ↔ string conversion, `strconv` is faster than `fmt`:

```go
// Bad
s := fmt.Sprint(rand.Int())
// BenchmarkFmtSprint-4    143 ns/op    2 allocs/op

// Good
s := strconv.Itoa(rand.Int())
// BenchmarkStrconv-4    64.2 ns/op    1 allocs/op
```

## Avoid repeated string-to-byte conversions

`[]byte("literal")` allocates each call. Hoist constant byte slices out of loops:

```go
// Bad
for i := 0; i < b.N; i++ {
  w.Write([]byte("Hello world"))
}
// BenchmarkBad-4   50000000   22.2 ns/op

// Good
data := []byte("Hello world")
for i := 0; i < b.N; i++ {
  w.Write(data)
}
// BenchmarkGood-4  500000000   3.25 ns/op
```

## Prefer Specifying Container Capacity

Allocate up front when the size is known.

### Map Capacity Hints

```go
make(map[T1]T2, hint)
```

The hint is approximate — it sizes the bucket count. Allocations may still occur as elements are added, but fewer of them.

```go
// Bad
files, _ := os.ReadDir("./files")
m := make(map[string]os.DirEntry)
for _, f := range files {
  m[f.Name()] = f
}

// Good
files, _ := os.ReadDir("./files")
m := make(map[string]os.DirEntry, len(files))
for _, f := range files {
  m[f.Name()] = f
}
```

### Slice Capacity

Slice capacity **is** preallocated — `append` is allocation-free until length hits capacity:

```go
make([]T, length, capacity)
```

```go
// Bad
data := make([]int, 0)
for k := 0; k < size; k++ {
  data = append(data, k)
}
// BenchmarkBad-4    100000000    2.48s

// Good
data := make([]int, 0, size)
for k := 0; k < size; k++ {
  data = append(data, k)
}
// BenchmarkGood-4   100000000    0.21s
```

When you know the length upfront and need to assign by index, use `make([]T, length)` directly.
