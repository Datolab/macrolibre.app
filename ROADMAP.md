# Roadmap — macrolibre.app MVP

Source of truth: `../srs-macrotracker-mvp.md` (workspace root), scoped here to
what `macrolibre.app` (the client) owns. Items owned by the `datocal.com` platform
are noted as external dependencies, not client work.

Status: **planning** — no code yet. Milestone dates below are targets from the
SRS, not commitments.

## M1 — Foundation (2026-09-01, ~3 weeks)

- [ ] Repo scaffolding, CI, PWA shell, IndexedDB layer
- [ ] Consume the open base dataset (built + published by `datocal.com`, not this repo)

**Done when:** PWA installs offline on iOS/Android/desktop browsers; local
search over the bundled dataset is < 100 ms; public repo live with CI green.

## M2 — Logging Core (~4 weeks after M1's dataset dependency lands)

- [ ] Text search, barcode scan, quick-add, favorites, custom foods/templates (FR-A-1..7)

**Done when:** all FR-A "Must" requirements pass QA, including camera barcode
scan on iOS Safari; internal dogfood median log time ≤ 7 s.

## M3 — Data Service *(external dependency, not client work)*

Owned by `datocal.com`: Verified Food DB API, dietitian pipeline, dataset release
signing. This repo only integrates with it (delta-sync consumption, tiered
verified lookups) once its API contract (public OpenAPI spec) is available.

## M4 — Adaptation + Pro (client parts)

- [ ] Trend weight + weekly adaptation engine + explanation cards (FR-D-1..7) — fully client-side, open source
- [ ] Client-side integration with `datocal.com`'s E2E sync API (behind `SyncPort`)
- [ ] Client-side Stripe/PPP checkout entry point (billing logic itself lives in `datocal.com`)

**Done when:** engine is within ±5% of the reference TDEE dataset; every
adjustment renders an explanation card; E2E sync passes the multi-device
conflict suite; checkout flow works against `datocal.com`'s billing API in ≥4 regions.

## M5 — Launch

- [ ] Public beta, self-host docs (`macrolibre/sync-server` reference — separate repo, not yet created)
- [ ] Hardening, client-side pentest, `CONTRIBUTING.md` + DCO sign-off (NFR-10)
- [ ] `v1.0` tag, reproducible build

**Done when:** ≥60% of active beta testers log ≥5 days/week in week 3;
pentest criticals = 0; self-host guide validated by an external tester; v1.0
tagged with a reproducible build.

## MVP success criteria (90 days post-launch)

Community/adoption metrics only — business/monetization KPIs (conversion
rate, B2B pipeline) are tracked privately in `datocal.com`, not published here,
since this is the public AGPL repo:

- ≥ 500 GitHub stars and ≥ 10 external contributors
- ≥ 5,000 monthly active browsers across launch markets
- Week-4 retention ≥ 25%
- ≥ 100 community food submissions, ≥ 60% approval rate

## Open decisions

- [x] Accept or revise [ADR-0001](docs/adr/0001-frontend-framework-selection.md) (ReScript) — **Accepted**
- [x] Accept or revise [ADR-0002](docs/adr/0002-adopt-hexagonal-architecture-for-the-spa-client.md) (hexagonal architecture) — **Accepted**
- [ ] Accept or revise [ADR-0003](docs/adr/0003-runtime-safety-strategy-boundary-decoding.md) (boundary decoding)
- [ ] Decide when/whether `macrolibre/sync-server` becomes its own repo
- [ ] Define the `datocal.com` ↔ `macrolibre.app` public OpenAPI contract referenced by SRS §2.5
