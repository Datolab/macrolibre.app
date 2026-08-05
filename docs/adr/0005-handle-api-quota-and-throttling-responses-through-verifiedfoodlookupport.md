# ADR-0005: Handle API quota and throttling responses through VerifiedFoodLookupPort

## Status

Accepted <!-- Proposed | Accepted | Deprecated | Superseded by [ADR-XXXX](XXXX-filename.md) -->

## Date

2026-08-05

## Context

`datocal.com`'s counterpart decision
([ADR-0005](../../../datocal.com/docs/adr/0005-enforce-api-usage-quotas-via-a-domain-rate-limit-port-backed-by-postgres.md))
commits the Verified Food DB API to returning `429` with `Retry-After` and
`X-RateLimit-{Limit,Remaining,Reset}` headers once a caller's tier quota
(FR-F-1 free tier, FR-F-2 Pro, FR-F-4 B2B) is exhausted. This client already
has a documented fallback for exactly this situation —
`docs/architecture.md`'s logging flow shows `S2{Online + tier OK?}` branching
to "local open dataset only" when the Verified API isn't usable — but that
diagram predates a concrete decision on *how* "tier OK?" gets decided or
surfaced through `VerifiedFoodLookupPort`.

Per [ADR-0003](0003-runtime-safety-strategy-boundary-decoding.md), no HTTP
detail (status codes, headers) may cross into `domain/`/`application/` code
undecoded — so this decision is about what `VerifiedDbHttpAdapter` decodes a
`429` (or a `200` carrying rate-limit headers) into, and what
`SearchFood`/`LookupFood` do with that value.

## Decision Drivers

- [ADR-0003] requires HTTP-shaped errors to become domain values at the
  adapter boundary, not leak status codes/headers into use cases
- The product vision (SRS §1.2) is built on "explainable" behavior — a user
  whose search silently degrades to local-only results without explanation
  contradicts that, and a generic error would only let the UI show "search
  failed," not "you're offline" vs. "you've used today's free lookups"
- NFR-2 (median ≤ 5 s log time) rules out blocking/retrying inside a search
  call while waiting out a quota window — a daily quota won't reset within
  any acceptable retry delay, so retrying is actively wrong here, not just
  wasteful
- FR-F-2's upgrade incentive (unlimited verified lookups on Pro) works
  better if the free-tier user can see they're approaching or have hit the
  daily limit, not just discover it via a failed search

## Options Considered

### Option 1: Explicit domain result variant, decoded at the adapter boundary

`VerifiedFoodLookupPort`'s result type gains a `QuotaExceeded(retryAt)`
variant alongside success/offline/error, decoded by `VerifiedDbHttpAdapter`
from `429` + `Retry-After`. On every response (including `200`), the adapter
also decodes `X-RateLimit-Remaining`/`Reset` into the result so the UI can
show "3 lookups left today" before exhaustion, not just react after.
`SearchFood` treats `QuotaExceeded` the same as offline for the actual
fallback (local dataset only, per the existing flow diagram) but passes the
distinct reason through so the UI's explanation card can say which one it
is.

- **Good:** Matches [ADR-0003]'s decode-at-boundary discipline exactly;
  keeps the existing local-fallback behavior intact while adding the
  "why" the product vision's explainability principle needs; remaining-quota
  visibility supports FR-F-2's upgrade motivation as an honest signal, not a
  dark pattern.
- **Bad:** One more variant every `VerifiedFoodLookupPort` call site must
  handle, versus a single generic error case.

### Option 2: Fold into a generic error case, fall back to local on any failure

Any non-2xx (or a decode failure) becomes one `Error` variant; `SearchFood`
falls back to local-only on any error, no distinction.

- **Good:** Smaller port surface; one code path handles offline, quota, and
  server errors alike.
- **Bad:** Can't tell the user why results are local-only, contradicting the
  product's explainability commitment; loses the remaining-quota signal
  FR-F-2 benefits from; makes it impossible to special-case "retry shortly"
  (a transient 5xx) differently from "quota resets at midnight" (a 429),
  even though the right client behavior genuinely differs.

### Option 3: Retry with backoff inside the adapter before surfacing anything

`VerifiedDbHttpAdapter` waits out `Retry-After` and retries transparently;
`SearchFood` never sees a throttled response unless retries are exhausted.

- **Good:** Use cases stay simple — no quota-handling logic above the
  adapter.
- **Bad:** Directly violates NFR-2 — a daily quota's `Retry-After` can be
  hours, so a "transparent retry" would either block the search far past
  the 5 s/15 s budget or require the adapter to silently give up and return
  something anyway, at which point it's just Option 1 or 2 with extra steps
  and a latency risk in between. Rejected.

## Decision

**Option 1.** `VerifiedFoodLookupPort`'s result type includes an explicit
`QuotaExceeded(retryAt)` variant (alongside offline/error), decoded by
`VerifiedDbHttpAdapter` from `429`/`Retry-After` per
[ADR-0003](0003-runtime-safety-strategy-boundary-decoding.md); rate-limit
headers are decoded on successful responses too, so the domain layer always
has remaining-quota information available to `SearchFood` and the UI, not
only at the moment of exhaustion.

## Consequences

### Positive

- Consistent with [ADR-0003] — no HTTP status codes or header parsing
  outside `infrastructure/`
- The existing local-fallback flow (`docs/architecture.md`'s logging
  diagram) now has a concrete, explainable trigger instead of an
  undifferentiated "not OK" branch
- Free-tier users can see approaching/hit quota before a search silently
  degrades, supporting FR-F-2 honestly
- `SearchFood` and any future use case built on the same port get a
  reusable, typed way to distinguish offline / quota / error without
  re-deciding this per call site

### Negative / Trade-offs

- More variants for every `VerifiedFoodLookupPort` consumer to handle than a
  single generic error would require
- Depends on `datocal.com`'s header contract
  ([ADR-0005](../../../datocal.com/docs/adr/0005-enforce-api-usage-quotas-via-a-domain-rate-limit-port-backed-by-postgres.md))
  actually landing in the public spec repo ([ADR-0004](0004-publish-the-public-api-contract-from-a-dedicated-spec-repo.md))
  before this can be implemented for real — until then this is a
  design-level decision, not yet buildable end-to-end

### Risks

- If the header names/semantics change once the spec repo formalizes them,
  the decode logic in `VerifiedDbHttpAdapter` needs updating — contained to
  one adapter, not a domain change, per [ADR-0002](0002-adopt-hexagonal-architecture-for-the-spa-client.md)
- Showing remaining-quota UI needs its own design pass (where/how it
  appears) — out of scope for this ADR, which only decides the domain/port
  shape

## Links

- Related: [ADR-0002](0002-adopt-hexagonal-architecture-for-the-spa-client.md)
- Related: [ADR-0003](0003-runtime-safety-strategy-boundary-decoding.md)
- Related: [ADR-0004](0004-publish-the-public-api-contract-from-a-dedicated-spec-repo.md)
- Related (backend-side twin): `datocal.com`
  [ADR-0005](../../../datocal.com/docs/adr/0005-enforce-api-usage-quotas-via-a-domain-rate-limit-port-backed-by-postgres.md)
- Source: `../../../srs-macrotracker-mvp.md` §3.6 (FR-F-1, FR-F-2, FR-F-4), §5 (NFR-2)
