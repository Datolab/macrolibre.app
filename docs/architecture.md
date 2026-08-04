# Architecture — macrolibre.app (client)

Scope: this document covers the **client** only. The hosted platform
(Verified Food DB, dietitian pipeline, billing, dataset signing) lives in the
separate, proprietary `datocal.com` repository. See `../srs-macrotracker-mvp.md`
in the workspace root for the full product SRS both repos derive from.

Status: [ADR-0001](adr/0001-frontend-framework-selection.md) (frontend
language) is **Accepted**. [ADR-0002](adr/0002-adopt-hexagonal-architecture-for-the-spa-client.md)
(hexagonal layering) and [ADR-0003](adr/0003-runtime-safety-strategy-boundary-decoding.md)
(boundary decoding) remain **Proposed** — the diagrams below reflect all
three, but only the language choice is settled.

## 1. System context

```mermaid
flowchart LR
    U[User - any modern browser] --> SPA[macrolibre.app SPA/PWA<br/>AGPL, local-first]
    SPA <--> IDB[(IndexedDB<br/>logs, weights, targets,<br/>bundled open dataset)]
    SPA <-->|optional, paid, via SyncPort| SYNCAPI[datocal.com Sync API]
    SPA <-->|tiered lookups, via VerifiedFoodLookupPort| VAPI[datocal.com Verified Food DB API]
    SPA -->|delta-sync, via a release-manifest reader| REL[datocal.com signed dataset releases]
    SPA -.->|self-host alternative to SyncAPI| SELFSYNC[macrolibre/sync-server<br/>reference impl, self-hosted]
```

The client never talks to a database directly. `SyncApiAdapter` and
`VerifiedDbHttpAdapter` are the only code aware that `datocal.com` exists on the
other end — a self-hoster can substitute `macrolibre/sync-server` behind the
same `SyncPort` without any domain/application change.

## 2. Hexagonal layering

```mermaid
flowchart TB
    subgraph Domain["domain/ (ReScript, no JS interop)"]
        ENT[Entities: FoodLog, WeightEntry,<br/>TargetSet, TargetAdjustment]
        ENGINE[Adaptation engine:<br/>TDEE estimate, trend weight,<br/>weekly adjustment + explanation]
        PORTS[Ports: FoodRepository, WeightRepository,<br/>VerifiedFoodLookupPort, SyncPort,<br/>BarcodeCapturePort, ClockPort]
    end
    subgraph Application["application/ (use cases)"]
        UC1[LogMeal]
        UC2[RecordWeight]
        UC3[ComputeWeeklyAdjustment]
        UC4[SearchFood]
        UC5[ExportData]
    end
    subgraph Infrastructure["infrastructure/ (JS interop, decoders per ADR-0003)"]
        IDB_A[IndexedDbFoodRepository]
        HTTP_A[VerifiedDbHttpAdapter]
        SYNC_A[SyncApiAdapter]
        CAM_A[BarcodeCameraAdapter]
        SW_A[ServiceWorkerAdapter]
    end

    Application --> Domain
    Infrastructure -.implements.-> PORTS
    UC1 --> ENT
    UC3 --> ENGINE
```

Domain and application code depend only on port interfaces, never on a
concrete adapter — enforced by [ADR-0002](adr/0002-adopt-hexagonal-architecture-for-the-spa-client.md).
Every arrow crossing into `infrastructure/` is a JS-interop boundary that must
decode through [ADR-0003](adr/0003-runtime-safety-strategy-boundary-decoding.md)'s
decoders before becoming a domain type.

## 3. Logging flow (FR-A)

```mermaid
flowchart TD
    START([User opens Log]) --> CHOICE{Entry method}
    CHOICE -->|Search| S1[Type query] --> S2{Online + tier OK?}
    S2 -->|Yes| S3[Local + Verified API<br/>merged, badged results]
    S2 -->|No| S4[Local open dataset only]
    S3 --> P[Confirm portion]
    S4 --> P
    CHOICE -->|Barcode camera| B1[Scan via BarcodeCapturePort] --> B2{In local cache/dataset?}
    B2 -->|Yes| P
    B2 -->|No| B3[Quick-add fallback<br/>+ optional submit to community] --> P
    CHOICE -->|Favorites/Recent| F1[One-tap re-log] --> DONE
    CHOICE -->|Quick add| Q1[Enter kcal + P/C/F] --> DONE
    P --> DONE([Saved via FoodRepository<br/>sync queued if Pro])
```

Median ≤ 5 s, p95 ≤ 15 s end-to-end (NFR-2) — every step in this flow runs
against local IndexedDB first; the Verified API is additive, never blocking.

## 4. Dataset delta-sync (client side of FR-C)

```mermaid
sequenceDiagram
    participant Client as macrolibre.app
    participant Rel as datocal.com (releases.datocal.com)
    Client->>Rel: request delta since installed version
    Rel-->>Client: manifest (version, checksum, changelog) + delta records
    Client->>Client: decode manifest (ADR-0003)
    alt signature + checksum valid
        Client->>Client: apply delta to IndexedDB dataset store
    else invalid / decode failure
        Client->>Client: reject delta, keep current version (FR-C-5 rollback-safe)
    end
```

## Open items

- The SRS (`srs-macrotracker-mvp.md` §2.5) names a third codebase,
  `macrolibre/sync-server` (public AGPL reference sync implementation), as a
  separate repo from both `macrolibre.app` and `datocal.com`. Only two local
  folders exist today (`macrolibre.app`, `datocal.com`) — decide whether/when to
  set up `sync-server` as its own repo.
- Hexagonal layering ([ADR-0002](adr/0002-adopt-hexagonal-architecture-for-the-spa-client.md))
  and boundary decoding ([ADR-0003](adr/0003-runtime-safety-strategy-boundary-decoding.md))
  are still **Proposed**. Nothing describing those layers here should be
  treated as final until they're Accepted; the frontend language
  ([ADR-0001](adr/0001-frontend-framework-selection.md)) is settled.
