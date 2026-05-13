# Concurrency

Mutexes, channels, goroutines, atomics.

## Zero-value Mutexes are Valid

```go
// Bad
mu := new(sync.Mutex)

// Good
var mu sync.Mutex
```

Mutex on a struct must be a non-pointer field, **never embedded**:

```go
// Bad — Lock/Unlock leak to public API
type SMap struct {
  sync.Mutex
  data map[string]string
}

// Good
type SMap struct {
  mu sync.Mutex

  data map[string]string
}
```

By convention, name it `mu`.

## Channel Size is One or None

Channels: unbuffered or size 1. Larger sizes need justification — what determines the size, what blocks writers when full, what happens then.

```go
// Bad
c := make(chan int, 64)

// Good
c := make(chan int, 1)
c := make(chan int)
```

## Use go.uber.org/atomic

Raw `sync/atomic` is easy to misuse — non-atomic reads of "atomic" fields are silent races. `go.uber.org/atomic` wraps the operations in typed wrappers and provides `atomic.Bool`:

```go
// Bad
type foo struct {
  running int32 // atomic
}
func (f *foo) start() {
  if atomic.SwapInt32(&f.running, 1) == 1 { return }
}
func (f *foo) isRunning() bool {
  return f.running == 1 // race!
}

// Good
type foo struct {
  running atomic.Bool
}
func (f *foo) start() {
  if f.running.Swap(true) { return }
}
func (f *foo) isRunning() bool {
  return f.running.Load()
}
```

## Don't fire-and-forget goroutines

Goroutines aren't free (stack memory, scheduler load) and unmanaged ones leak resources, prevent GC, and cause hard-to-debug issues. Use [go.uber.org/goleak](https://pkg.go.dev/go.uber.org/goleak) in tests.

Every goroutine must satisfy **both**:

1. Predictable stop time, **OR** a way to signal it to stop
2. A way to block and wait for it to exit

```go
// Bad — no stop, no wait
go func() {
  for {
    flush()
    time.Sleep(delay)
  }
}()

// Good
var (
  stop = make(chan struct{}) // signals stop
  done = make(chan struct{}) // confirms exit
)
go func() {
  defer close(done)

  ticker := time.NewTicker(delay)
  defer ticker.Stop()
  for {
    select {
    case <-ticker.C:
      flush()
    case <-stop:
      return
    }
  }
}()

// Elsewhere
close(stop) // signal
<-done      // wait
```

### Wait for goroutines to exit

Two patterns:

**`sync.WaitGroup`** for multiple goroutines:

```go
var wg sync.WaitGroup
for i := 0; i < N; i++ {
  wg.Go(func() { /* ... */ })
}
wg.Wait()
```

**`chan struct{}`** for a single goroutine:

```go
done := make(chan struct{})
go func() {
  defer close(done)
  // ...
}()
<-done
```

### No goroutines in init()

`init()` must not spawn goroutines. Background goroutines belong to an exposed object with a `Close`/`Stop`/`Shutdown` method that signals + waits:

```go
// Bad
func init() {
  go doWork()
}

// Good
type Worker struct {
  stop chan struct{}
  done chan struct{}
}

func NewWorker() *Worker {
  w := &Worker{
    stop: make(chan struct{}),
    done: make(chan struct{}),
  }
  go w.doWork()
  return w
}

func (w *Worker) doWork() {
  defer close(w.done)
  for {
    select {
    case <-w.stop:
      return
      // ... other cases
    }
  }
}

func (w *Worker) Shutdown() {
  close(w.stop)
  <-w.done
}
```

This way:
- Goroutine spawns only when the user requests it
- The user can free its resources

If the worker manages multiple goroutines, use `WaitGroup` internally.

## Copy Slices and Maps at Boundaries

Slices and maps share underlying memory across function calls. Copy at trust boundaries — see [guidelines.md](guidelines.md) for details. Especially relevant under concurrency: returning an internal map from behind a mutex without copying lets the caller race against your internal state.

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
