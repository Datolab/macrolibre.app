# ADR-0004: Publish the public API contract from a dedicated spec repo

## Status

Accepted <!-- Proposed | Accepted | Deprecated | Superseded by [ADR-XXXX](XXXX-filename.md) -->

## Date

2026-08-05

## Context

SRS §2.5 requires the API contract between `macrolibre.app` and
`datocal.com` to be public — an OpenAPI spec living in the GitHub org — even
though `datocal.com`'s implementation is private on GitLab. Both repos
already depend on this contract: this client consumes it (search/lookup
against the Verified Food DB, delta-sync against dataset releases per Epic
C, the Pro sync API, the Stripe checkout entry point), and `datocal.com`
implements it. Neither repo is a natural sole owner — a contract change
driven by client needs shouldn't require a private-GitLab PR just to
propose it, and one driven by backend implementation details shouldn't force
a commit into this repo.

This repo's [ADR-0003](0003-runtime-safety-strategy-boundary-decoding.md)
already flags the risk this decision resolves: without a contract-test
suite against the public OpenAPI spec, this client's boundary decoders and
`datocal.com`'s boundary constructors can drift apart silently until a
decode failure surfaces it at runtime. That's only fixable once the spec is
a single, independently versioned artifact both repos pin to and test
against — not something embedded uniquely inside one implementation.

`ROADMAP.md` already lists "Define the `datocal.com` ↔ `macrolibre.app`
public OpenAPI contract referenced by SRS §2.5" as an open decision blocking
real M3/M4 integration; this ADR settles where that contract lives before
its content is designed.

## Decision Drivers

- SRS §2.5 hard requirement: the spec must be public/GitHub regardless of
  `datocal.com`'s own privacy
- Contract-testability
  ([ADR-0003](0003-runtime-safety-strategy-boundary-decoding.md)'s drift
  risk) requires one versioned source of truth both repos pin to
- Neither repo should unilaterally own a contract the other equally depends
  on — avoids one side's release cadence gating the other's ability to
  change the contract
- As the AGPL public side, this repo's maintainers and outside contributors
  need to be able to propose contract changes without needing access to the
  private `datocal.com` repo
- Avoid duplicating the spec into both repos — copies drift silently

## Options Considered

### Option 1: Dedicated public spec repo (e.g. `macrolibre/api-spec`)

A new, standalone public repo whose only content is the OpenAPI spec(s),
versioned/tagged independently of either implementation.

- **Good:** Single source of truth; independently versioned (semver tags,
  not tied to either app's release cadence); both repos consume it
  identically (a pinned fetch step in CI); natural home for the
  contract-test suite that validates both implementations against it;
  contributors to this AGPL project can propose contract changes via a
  normal public PR, without ever touching the private backend repo.
- **Bad:** A third repo to create and maintain; a contract change now needs
  a tag plus two follow-up pin-bump PRs instead of one in-place edit.

### Option 2: Embed under this repo's `docs/openapi/`

Since this repo is already public on GitHub, satisfy SRS §2.5's location
constraint by placing the spec here directly.

- **Good:** No new repo; already public; simplest to start; keeps
  everything client-side contributors touch in one place.
- **Bad:** Wrongly implies this client owns a contract `datocal.com`
  equally depends on and implements; a backend-driven contract change
  requires `datocal.com` to open a PR into this AGPL repo; the spec's
  versioning becomes entangled with this app's own version/tags (v1.0 of
  the client vs. v1 of the API contract are different things that would be
  forced to share a home).

### Option 3: Consume a mirror generated from `datocal.com`

Treat `datocal.com` as the source of truth (it has the deepest stake in the
exact schema) and consume a generated public mirror from there.

- **Good:** Nothing to build in this repo; schema stays authored next to the
  implementation it must match.
- **Bad:** Violates SRS §2.5 directly — the *source* would be private, not
  just the implementation; this repo's maintainers (the public, AGPL side)
  would be auditing a generated mirror rather than the source, and could not
  propose a contract change without private-repo access they don't have.

## Decision

**Option 1.** The contract is published from a dedicated public spec repo.
This repo pins a specific tagged version (a build-time fetch step in CI, not
a git submodule, to avoid submodule tooling overhead) and adds a
contract-test stage validating its boundary decoders
([ADR-0003](0003-runtime-safety-strategy-boundary-decoding.md)) against that
pinned version — closing the drift risk that ADR flags. The repo's exact
name and governance are operational details for a follow-up, not part of
this decision.

## Consequences

### Positive

- Satisfies SRS §2.5 directly — the spec's source is public regardless of
  `datocal.com`'s privacy
- Unblocks the contract-test suite flagged as a risk in
  [ADR-0003](0003-runtime-safety-strategy-boundary-decoding.md), with one
  artifact both implementations test against
- This repo's contributors can propose contract changes through a normal
  public PR against the spec repo, consistent with the AGPL open-core model
- The contract can be tagged/versioned independently of this app's own
  release cadence

### Negative / Trade-offs

- A third repo to create and maintain (CI, issue tracker, contribution
  guidelines, however minimal)
- A contract change now requires two follow-up pin-bump PRs (one per
  implementation) instead of a single in-place edit
- This ADR records the topology only — the actual endpoint/schema design
  (SRS §2.5, needed for real M3/M4 integration) is still open work

### Risks

- If a pin-bump is skipped after a spec change, this client can silently run
  against a stale contract version relative to `datocal.com` — mitigate by
  having the contract-test suite fail CI when the pinned version is stale,
  not only when it's missing
- Governance of the new repo (e.g., whether `macrolibre.app` maintainers can
  accept a breaking contract change, or only Datolab) is not decided here
  and needs a follow-up decision once the repo exists

## Links

- Related: [ADR-0001](0001-frontend-framework-selection.md)
- Related: [ADR-0002](0002-adopt-hexagonal-architecture-for-the-spa-client.md)
- Related: [ADR-0003](0003-runtime-safety-strategy-boundary-decoding.md) —
  this decision resolves that ADR's contract-drift risk
- Related (backend-side twin): `datocal.com`
  [ADR-0004](../../../datocal.com/docs/adr/0004-publish-the-public-api-contract-from-a-dedicated-spec-repo.md)
- Source: `../../../srs-macrotracker-mvp.md` §2.5
