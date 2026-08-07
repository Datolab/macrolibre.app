# ADR-0006: Ingest the open base bundle into IndexedDB

## Status

Accepted <!-- Proposed | Accepted | Deprecated | Superseded by [ADR-XXXX](XXXX-filename.md) -->

## Date

2026-08-06

## Context

The client ships an **open base** food dataset built and published by
`datocal.com` (FR-B-1). This ADR is the **consumer** half of a cross-repo
data-artifact contract; the **producer** half —
`datocal.com` [ADR-0007](../../../datocal.com/docs/adr/0007-encode-the-open-base-bundle-as-gzipped-ndjson.md)
— sets the encoding as **gzipped NDJSON**, one `Food` JSON object per line,
sorted by a deterministic id, with a sidecar manifest and ODbL attribution.

This client must decide how it *ingests* that bundle into its IndexedDB
`foods_local` store (SRS §4), how it satisfies **<100 ms local search**
(M1 "done when"), and how it honours the ODbL attribution that
`datocal.com` [ADR-0006](../../../datocal.com/docs/adr/0006-source-and-license-the-open-base-dataset.md)
attaches to the data. Per this repo's
[ADR-0003](0003-runtime-safety-strategy-boundary-decoding.md), external data
must cross the boundary through explicit decoders — the bundle is exactly such
a boundary.

## Decision Drivers

- <100 ms local search over the bundled dataset (M1 completion criterion)
- Offline-first: parse once at install, then work fully offline
- Bounded memory: a ≤25 MB bundle must not be held whole in memory while loading
- Every record crosses the boundary through an ADR-0003 decoder — a malformed
  line is rejected, not trusted
- Honour ODbL: the OFF attribution must be surfaced in the UI

## Options Considered

### Bundle parsing

**Streamed decode via `DecompressionStream` (chosen).** `fetch` the
`.ndjson.gz`, pipe through `DecompressionStream('gzip')`, split into lines, and
decode each line through the boundary decoder into a domain `Food`, upserting
into `foods_local` in batched IndexedDB transactions.

- **Good:** Constant memory; resilient (a bad line is skipped, logged); reuses
  the ADR-0003 decoder that the live API path already needs. `DecompressionStream`
  is native in current browsers — no gzip library.
- **Bad:** Per-line parse cost at install — one-time, acceptable.

*(Rejected: reading the whole file into memory then `JSON.parse` — a 25 MB
memory spike and no partial-failure resilience.)*

### Search index for <100 ms

**IndexedDB index on a normalized name key (chosen).** Store, alongside each
record, a normalized search field (lowercased, accent-stripped `name_en` /
`name_es`) and index it; run prefix/substring lookups via `IDBKeyRange`.

- **Good:** Uses the store the SRS already mandates; no extra engine; index
  built as records are inserted; adequate for the regional dataset size.
- **Bad:** Substring (non-prefix) search needs care; may need a token/n-gram
  field if plain prefix search proves insufficient.

*(Rejected for now: a separate in-memory full-text index — extra memory and a
dependency, unnecessary until IndexedDB prefix search is shown to miss <100 ms.
Rejected: precomputing search tokens in the bundle — keeps the producer format
raw per ADR-0007; the client owns its index.)*

## Decision

Ingest the gzipped NDJSON bundle by streaming it through
`DecompressionStream`, decoding each line via the ADR-0003 boundary decoder into
a domain `Food`, and upserting into `foods_local` behind a hexagonal
`OpenBaseBundlePort` (so the parse/store logic is testable with an in-memory
fake, no real IndexedDB). Each record stores a normalized search field indexed
in IndexedDB; local search runs against that index to meet <100 ms. The OFF/ODbL
attribution from the bundle manifest is surfaced in the app (e.g., an
"About / data sources" view), satisfying `datocal.com` ADR-0006.

M3 delta-sync reuses the same decoder and upsert path (changed records upserted,
`removed` ids deleted), so ingestion is written once for both snapshot and delta.

## Consequences

### Positive

- One decode/upsert path for the install bundle and M3 deltas
- Constant-memory install; resilient to a bad record
- Reuses the ADR-0003 boundary decoder — no bespoke bundle parser to trust
- No second storage engine; stays within the SRS's IndexedDB model

### Negative / Trade-offs

- Install-time parse of the full bundle (one-time)
- Prefix-first search may later need an n-gram/token field if substring search
  quality demands it — revisit against the <100 ms target with real data

### Risks

- If IndexedDB prefix search misses <100 ms at the real dataset size, a fallback
  (n-gram field, or an in-memory index for the working set) is needed — measure
  before adding it
- **Forgetting the ODbL attribution is a licence breach** (datocal.com ADR-0006):
  the attribution surface is a required part of this work, not optional polish

## Links

- Twin (producer): `datocal.com`
  [ADR-0007](../../../datocal.com/docs/adr/0007-encode-the-open-base-bundle-as-gzipped-ndjson.md)
- Depends on the data licence: `datocal.com`
  [ADR-0006](../../../datocal.com/docs/adr/0006-source-and-license-the-open-base-dataset.md)
  (ODbL attribution)
- Follows: [ADR-0003](0003-runtime-safety-strategy-boundary-decoding.md)
  (boundary decoding) and [ADR-0002](0002-adopt-hexagonal-architecture-for-the-spa-client.md)
- Relates to: `macrolibre-api-spec` `releases.yaml` (`DatasetDelta` shape, M3)
