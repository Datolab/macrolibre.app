# ADR-0002: Adopt hexagonal architecture for the SPA client

## Status

Proposed <!-- Proposed | Accepted | Deprecated | Superseded by [ADR-XXXX](XXXX-filename.md) -->

## Date

2026-08-04

## Context

The engineering standards for this machine (`~/.claude/CLAUDE.md`) mandate
hexagonal architecture (ports & adapters) for every project: the domain/application
core must not depend on infrastructure, and domain/application tests must never
touch a DB, network, or filesystem. `macrolibre.app` is a client, not a server,
but the same split applies: the "infrastructure" here is IndexedDB, the
Verified-DB HTTP API, the device camera, the service worker, and (later) Stripe
checkout — exactly the boundary [[0001]] identifies as the app's real source
of runtime risk.

The domain also carries real business logic worth protecting from framework
churn: TDEE estimation, trend-weight smoothing, and the weekly explainable
target adjustment (FR-D-1..7) are pure calculations that must stay correct,
testable in isolation, and readable enough to justify the "explainability"
promise (FR-D-4) — every adjustment ships its own math breakdown.

## Decision Drivers

- Enforce CLAUDE.md's hexagonal rule uniformly, even for a frontend-only repo
- Keep the adaptation engine (FR-D) and logging domain (FR-A) testable without
  IndexedDB, network, or a rendered UI
- Concentrate all JS/browser-API interop (the real risk per [[0001]]) into a
  thin, swappable adapter layer
- Make the eventual sync backend (`datocal.com`, hosted separately) swappable
  behind a port, so self-hosters (FR-E-6) can point the same client at a
  different sync implementation without touching domain code

## Options Considered

### Option 1: Conventional feature-folder SPA structure

Group code by feature/screen (`features/logging/`, `features/coaching/`, ...),
mixing UI, state, and API calls per folder.

- **Good:** Familiar to most SPA developers; less upfront structure to design; fast to start.
- **Bad:** No enforced boundary between domain logic and IndexedDB/HTTP/camera
  code — exactly the coupling CLAUDE.md's hexagonal rule exists to prevent;
  domain logic (TDEE math, adjustment engine) ends up untestable without
  mocking browser APIs.

### Option 2: Hexagonal (ports & adapters), domain/application/infrastructure

Structure per CLAUDE.md's recommended layout, adapted to a client app:

```
src/
├── domain/          # Entities (FoodLog, WeightEntry, TargetSet, TargetAdjustment),
│                     # adaptation-engine domain service, port interfaces
├── application/      # Use cases: LogMeal, RecordWeight, ComputeWeeklyAdjustment,
│                     # SearchFood, ExportData — orchestrate domain via ports
└── infrastructure/   # Adapters: IndexedDbFoodRepository, VerifiedDbHttpAdapter,
                       # BarcodeCameraAdapter, SyncApiAdapter, ServiceWorkerAdapter
```

Ports (defined in `domain/`) include: `FoodRepository`, `WeightRepository`,
`VerifiedFoodLookupPort`, `SyncPort`, `BarcodeCapturePort`, `ClockPort`.

- **Good:** Matches CLAUDE.md's mandatory standard exactly; domain/application
  tests run with zero IndexedDB/network/camera dependency (fast, deterministic,
  fits the TDD workflow); the interop-heavy code [[0001]] flags as the real
  risk is isolated to `infrastructure/` and covered by [[0003]]'s boundary decoding.
- **Bad:** More upfront structure and indirection than a feature-folder app
  strictly needs at MVP size; risk of over-abstracting a small client if ports
  are added speculatively rather than where a real seam exists (e.g., don't
  introduce a port for something with only one possible implementation).

## Decision

**Option 2: hexagonal architecture**, per CLAUDE.md's standing rule, scoped to
what this MVP actually needs — a handful of ports (`FoodRepository`,
`WeightRepository`, `VerifiedFoodLookupPort`, `SyncPort`, `BarcodeCapturePort`),
not one per infrastructure call. The domain layer owns the adaptation engine
(FR-D) and logging entities (FR-A/§4 data model); the application layer owns
use-case orchestration; the infrastructure layer owns every IndexedDB, HTTP,
camera, and service-worker touchpoint.

## Consequences

### Positive

- Domain/application tests (TDEE math, trend-weight smoothing, weekly
  adjustment, explanation generation) run with no IndexedDB/network — fast,
  deterministic, matches CLAUDE.md's TDD mandate directly
- `SyncPort` being an interface (not a concrete `datocal.com` client) means
  self-hosters (FR-E-6) can swap in the reference `sync-server` implementation
  without touching domain/application code
- Concentrates [[0001]]'s identified risk surface (browser API interop) into
  `infrastructure/`, where [[0003]]'s decoding strategy applies uniformly

### Negative / Trade-offs

- More files/indirection than a feature-folder MVP strictly requires;
  discipline is needed to avoid adding ports "just in case" rather than where
  a real swap point exists
- Slightly slower initial scaffolding while the port interfaces are designed,
  vs. jumping straight into feature code

### Risks

- If ports are over-designed before requirements are firm, refactoring churn
  could exceed what a lighter structure would have cost — mitigate by adding
  ports only for the boundaries the SRS already names (storage, verified
  lookup, sync, camera), not speculative future ones

## Links

- Related: [ADR-0001](0001-frontend-framework-selection.md)
- Related: [ADR-0003](0003-runtime-safety-strategy-boundary-decoding.md)
- Standard: `~/.claude/CLAUDE.md` §"Hexagonal Architecture (Ports & Adapters)"
- Source: `srs-macrotracker-mvp.md` §3.1 (Epic A), §3.4 (Epic D), §3.5 (FR-E-6), §4 (Data Model)
