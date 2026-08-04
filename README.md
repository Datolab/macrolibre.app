# macrolibre.app

An open-source, local-first, browser-based (SPA/PWA) adaptive nutrition and
macro tracker. Full logging, macro breakdowns, and custom targets work
forever, offline, with no account and no ads — the client is AGPL-3.0,
auditable by anyone.

> **Status: planning.** No application code exists yet. See
> [`docs/architecture.md`](docs/architecture.md) and [`docs/adr/`](docs/adr/)
> for the proposed design, and [`ROADMAP.md`](ROADMAP.md) for the MVP plan.
> The product SRS this repo derives from lives at
> [`../srs-macrotracker-mvp.md`](../srs-macrotracker-mvp.md) in the local workspace.

## What this is

- **Local-first**: every core feature — search, barcode scan, quick-add,
  weight tracking, weekly target adjustment — works fully offline against a
  bundled open food dataset. No sign-up required, ever.
- **Explainable**: the adaptive coaching engine runs entirely client-side; the
  algorithm is open source, and every target adjustment ships a plain-language
  breakdown of the math behind it.
- **Privacy-first**: no ads, no third-party trackers, no data sales. Optional
  paid sync uses end-to-end encryption — the server never sees plaintext health data.
- **Regionally relevant**: portion units, language (English + Spanish es-419),
  and a dietitian-verified food database starting with Central America.

## Relationship to the hosted platform

This client is free and fully functional without any paid service. A separate,
proprietary platform (`datocal.com`, hosted at `api.datocal.com`) provides optional
paid features this client talks to through typed ports, never directly:

- Multi-device sync + backup (Kcal Pro)
- Unlimited verified regional food database lookups + weekly coaching application
- The signed, versioned dataset release pipeline this client pulls delta updates from

Self-hosters can run their own sync backend instead of `datocal.com` — see the
(forthcoming) `macrolibre/sync-server` reference implementation.

**Trademark note:** "MacroLibre" name/logo are Datolab trademarks even though
the code is AGPL-3.0 — forks must rename.

## Architecture

See [`docs/architecture.md`](docs/architecture.md) for system context,
hexagonal layering (domain/application/infrastructure), and key flows
(logging, dataset delta-sync). Key decisions:

| ADR | Decision | Status |
| :---- | :---- | :---- |
| [0001](docs/adr/0001-frontend-framework-selection.md) | Frontend language/framework: ReScript | Accepted |
| [0002](docs/adr/0002-adopt-hexagonal-architecture-for-the-spa-client.md) | Hexagonal architecture (ports & adapters) for the client | Accepted |
| [0003](docs/adr/0003-runtime-safety-strategy-boundary-decoding.md) | Decode all external data at infrastructure boundaries | Proposed |

## Roadmap

See [`ROADMAP.md`](ROADMAP.md) for MVP milestones and completion criteria.

## License

[GNU AGPL-3.0](LICENSE). Commercial licenses (for closed-source embedding) are
available from Datolab — this exists specifically so the AGPL copyleft
doesn't block legitimate commercial use, while still protecting the open
client from unlicensed closed forks.

## Contributing

Not yet open for contributions — the project is in the planning phase.
`CONTRIBUTING.md` and a DCO sign-off process will land before the first public
milestone (M1, see `ROADMAP.md`).
