---
name: go-style-review
description: Review Go code against the Uber Go Style Guide and produce PR-style review comments with inline diff suggestions. Flags rule violations across naming, imports, errors, concurrency, performance, and testing, and shows the exact fix as a unified diff. Use when reviewing Go code, auditing a .go file or PR, asked "review this Go code", "check this against Uber Go style", "uber go review", "audit go file", "is this idiomatic Go", or when given a Go diff to critique. Review-only — does not run lint. Source: https://github.com/uber-go/guide/blob/master/style.md
---

# Golang Style Review

Review Go code against the Uber Go Style Guide. One comment per violation: rule name, what's wrong, inline diff fix.

## Workflow

1. Identify scope: a file, a package, a PR diff, or a pasted snippet. Stay inside that scope.
2. Load [checklist.md](checklist.md) — compact scan table of every rule pattern.
3. Walk the code top-to-bottom. For each match in the checklist, draft a comment using the format below.
4. Need the verbatim rule text or a Bad/Good example from the guide? Open the topic file:
   - [style.md](style.md) — naming, imports, struct/map init, scope, embedding, line length, raw strings
   - [guidelines.md](guidelines.md) — interfaces, receivers, enums, time, type assertions, panics, globals, `init()`, `os.Exit`
   - [errors.md](errors.md) — wrapping (`%w` vs `%v`), naming (`Err*`/`*Error`), handle-once
   - [concurrency.md](concurrency.md) — mutexes, channels, goroutines, atomics
   - [performance.md](performance.md) — `strconv` over `fmt`, byte conversion, capacity hints
   - [testing.md](testing.md) — table tests, parallel tests, functional options
5. Output the review. End with the summary line.

## Output format

One block per violation. Always include: location, rule name, one-sentence issue, unified diff fix.

```
<file>:<line[-line]> — Rule: <Rule Name>
Issue: <one sentence, no hedging>
Fix:
```diff
- <current code>
+ <suggested code>
```
```

Severity prefix when the review has more than a few items:

- **Critical** — bug, race, goroutine leak, panic path, missing `comma-ok`, raw `sync/atomic` flag.
- **Warning** — clarity/style with material impact (deep nesting, `"failed to"`, no field tags, `log + return`).
- **Nit** — polish (`var x T` over `T{}`, raw string literals, redundant type on `var`).

See [examples.md](examples.md) for the rendered form across all three severities.

## Review discipline

- **Stay in scope.** Don't flag pre-existing code outside the diff unless the user asked for a full-file audit.
- **Cite the rule by name** as it appears in the guide (e.g., "Handle Errors Once", "Reduce Nesting"). Don't paraphrase.
- **One rule per comment.** If a line breaks two rules, emit two blocks.
- **Don't duplicate.** If the same violation repeats, flag the first occurrence and add `(also at: line X, line Y)`.
- **Hot-path performance rules** (`strconv`, byte hoisting, capacity hints) apply only on hot paths. If unclear, ask rather than assert: "Is this on a hot path? If yes — see Slice Capacity."
- **Ambiguity:** when context could justify either form, ask, don't verdict.

## Summary line

End the review with one line: `Review: N critical, M warning, K nit. <scope>`.

If nothing was found: `No Uber Go style violations found in <scope>.`

## Source

Full guide: https://github.com/uber-go/guide/blob/master/style.md
