# ADR-0003: Runtime-safety strategy — decode all external data at the boundary

## Status

Proposed <!-- Proposed | Accepted | Deprecated | Superseded by [ADR-XXXX](XXXX-filename.md) -->

## Date

2026-08-04

## Context

[[0001]] chose ReScript specifically because its compiler eliminates whole
classes of runtime error (no `null`, exhaustive pattern matching, sound types)
— but only for code the compiler actually typechecks. The moment data crosses
into the app from outside — an IndexedDB record, a Verified-DB API response, a
signed dataset-release manifest (FR-C-3), a barcode scan result, a future
Stripe checkout callback — it arrives as untyped `Js.Json.t`/JS values that
ReScript's guarantees do not cover. [[0002]]'s hexagonal split concentrates
exactly this data in `infrastructure/`; this ADR decides what happens the
moment it enters.

This is the practical answer to the team's "rock-solid, runtime-error-free"
requirement: the language choice in [[0001]] only pays off if every external
boundary is forced to prove its data matches the domain's expectations before
that data is allowed to touch domain/application code.

## Decision Drivers

- Untyped data (JSON, IndexedDB, camera/barcode results) is the app's actual
  runtime-risk surface, per [[0001]]'s reasoning — this ADR is the concrete
  mechanism for closing it
- Dataset releases are signed and versioned (FR-C-1..3); a malformed or
  unexpected-shape record should fail loudly and locally, not corrupt local state
- CLAUDE.md's TDD mandate requires domain/application tests with zero I/O —
  decoders are the seam where "untrusted input" tests belong instead
- Failure must be recoverable, not a crash: FR-C-5 requires the client to roll
  back a corrupted dataset version rather than break

## Options Considered

### Option 1: Unsafe casts at the boundary (`Obj.magic`, `%raw`, blind field access)

Treat incoming JSON as already matching the expected ReScript type.

- **Good:** Zero boilerplate, fastest to write.
- **Bad:** Completely defeats the reason ReScript was chosen in [[0001]] — a
  malformed API response or a schema-drifted IndexedDB record (e.g., after an
  app update changes a record shape) becomes an uncaught runtime failure deep
  inside domain code, exactly the outcome this project is trying to eliminate.

### Option 2: Hand-rolled decoder functions per boundary type, no library

Each infrastructure adapter writes its own `decodeFoodRecord : Js.Json.t => result<food, string>`-style function using pattern matching on `Js.Json.classify`.

- **Good:** No new dependency; fully explicit; easy to review.
- **Bad:** Significant boilerplate repeated across every boundary (IndexedDB
  records, API responses, manifest files); easy to accidentally skip a field
  check under time pressure, silently reintroducing Option 1's risk.

### Option 3: Decoding-combinator library (e.g., `@glennsl/bs-json` or equivalent) at every boundary

Every value crossing an infrastructure boundary is run through a composable
decoder that returns `result<t, decodeError>` — never `t` directly.

- **Good:** Consistent, low-boilerplate decoders; failure is a typed value the
  caller must handle, not an exception; composable across nested shapes
  (dataset manifests, API envelopes); makes "decode failure" a first-class,
  testable domain-visible state (needed for FR-C-5 rollback and FR-A-6
  graceful offline queuing).
- **Bad:** One more dependency in the interop-heavy infrastructure layer;
  decoder-writing is still manual work that must be kept in sync with backend
  (`datocal.com`) API/schema changes.

## Decision

**Option 3.** Every `infrastructure/` adapter that receives external data —
`IndexedDbFoodRepository`, `VerifiedDbHttpAdapter`, `SyncApiAdapter`,
`BarcodeCameraAdapter`, the dataset-release manifest reader — must decode raw
input through an explicit decoder before it becomes a domain type. Decoders
return `result<t, decodeError>`; there is no code path where `Js.Json.t` (or
any `%raw`/`Obj.magic` value) is coerced directly into a domain type.
Decode failures are:

- Logged with enough context to reproduce, never silently swallowed
- Surfaced as a typed result the application layer must branch on (never an
  uncaught exception) — e.g., a bad dataset delta triggers the FR-C-5 rollback
  path instead of crashing
- Covered by tests seeded with malformed/partial/unexpected-shape fixtures, in
  addition to the happy path, per CLAUDE.md's TDD mandate

## Consequences

### Positive

- Closes the gap [[0001]] identified: ReScript's compiler guarantees now
  extend, in practice, to every value the domain layer ever sees
- Decode failure becomes a designed, tested state (supports FR-C-5 rollback,
  FR-A-6 offline queuing) instead of an unhandled exception
- A `datocal.com` API contract change (breaking response shape) fails at the
  decoder with a clear error, not as a mystery crash three layers deeper

### Negative / Trade-offs

- Every new field or endpoint requires a decoder update — more upfront work
  per integration than trusting the shape
- Decoders can drift from the actual `datocal.com` OpenAPI contract if not kept in
  sync deliberately; needs a process (e.g., contract tests against the public
  OpenAPI spec mentioned in the SRS §2.5 topology) rather than pure discipline

### Risks

- Without contract tests against `datocal.com`'s public OpenAPI spec, decoders and
  the real API can silently diverge until a decode failure surfaces it in
  production — recommend adding a contract-test suite once the OpenAPI spec exists

## Links

- Related: [ADR-0001](0001-frontend-framework-selection.md)
- Related: [ADR-0002](0002-adopt-hexagonal-architecture-for-the-spa-client.md)
- Source: `srs-macrotracker-mvp.md` §3.2 (FR-B-3), §3.3 (Epic C), §3.1 (FR-A-6), §2.5 (public OpenAPI contract)
