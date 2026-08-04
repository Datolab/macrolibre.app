# ADR-0001: Frontend language & framework selection

## Status

Proposed <!-- Proposed | Accepted | Deprecated | Superseded by [ADR-XXXX](XXXX-filename.md) -->

## Date

2026-08-04

## Context

`macrolibre.app` is an AGPL-3.0, local-first SPA/PWA. Per the SRS
(`srs-macrotracker-mvp.md` in the `kcal/` workspace root), the client must hit:

- NFR-1/2: UI interaction < 200 ms p95, local search < 100 ms, median meal-log ≤ 5 s
- NFR-3: initial app shell ≤ 2 MB gzipped
- NFR-4: full offline capability via service worker, Lighthouse PWA-installable
- NFR-11/12: WCAG 2.1 AA, last-2-versions evergreen browsers incl. iOS Safari PWA quirks

Explicit constraint from the team: there is no hiring pool to protect, so
framework popularity is not a decision driver. The stated priority is a
**"rock-solid, runtime-error-free" app** — correctness matters more than
ecosystem size or contributor familiarity.

The app is also unusually **interop-heavy** for a "just use a safe language"
argument: barcode scanning via the device camera, IndexedDB persistence,
service worker lifecycle, and (eventually) a Stripe checkout embed for Pro
billing all require talking to native browser/JS APIs. Any language's runtime
safety guarantee is only as strong as its interop boundary.

## Decision Drivers

- Runtime correctness over ecosystem familiarity (no hiring constraint)
- The app's real defect surface is concentrated in browser-API interop
  (camera, IndexedDB, service worker, payments), not in pure calculation logic
  — so the interop story matters as much as the type system's core guarantees
- Small, tree-shakeable bundle to hit the ≤2 MB shell budget
- Mature offline/PWA tooling (service worker, background sync) still needs to exist somewhere in the stack
- Fits the hexagonal split in [[0002]]: a language with strong compile-time
  guarantees for domain/application code, callable from thin JS infrastructure adapters

## Options Considered

### Option 1: TypeScript (strict) + Solid or React

Mainstream JS-family stack; runtime safety comes from strict TS plus
boundary validation (Zod, see [[0003]]) rather than the type system's own guarantees.

- **Good:** Largest ecosystem for PWA/offline tooling (`vite-plugin-pwa`,
  Workbox), IndexedDB wrappers (Dexie), Stripe.js bindings, camera/barcode
  libraries; fastest path to shipping M1/M2 on the SRS roadmap; easiest for
  external OSS contributors to onboard (NFR-10 goal: ≥10 contributors).
- **Bad:** TypeScript's types are erased at runtime and don't prevent `null`/`undefined`
  bugs, unhandled union cases, or bad data crossing an API/IndexedDB boundary —
  all of that safety has to be manually re-implemented via lint rules,
  exhaustiveness checks, and validation libraries.

### Option 2: Elm

The purest "no runtime exceptions" language available for the browser: no
`null`, no runtime type errors, compiler-enforced exhaustive pattern matching,
proven in production to eliminate uncaught exceptions.

- **Good:** The strongest possible guarantee for the domain/application logic
  (TDEE math, trend-weight smoothing, target adjustments) — exactly the kind
  of pure calculation this app leans on for its "explainable coaching" feature (FR-D-4).
- **Bad:** All JS interop goes through **ports** (async message-passing), which
  is a poor fit for camera access, IndexedDB, service worker registration, and
  Stripe checkout — precisely this app's biggest sources of *real* runtime
  risk. Ports push that risk into an untyped boundary that Elm's guarantee
  does not cover, and the PWA/offline tooling ecosystem for Elm is effectively
  nonexistent, meaning it would all be hand-rolled and hand-tested.

### Option 3: ReScript

Same category of compile-time guarantees as Elm (variants, no `null`,
exhaustive pattern matching, sound type system) but with **direct typed JS
interop** instead of a ports/message boundary — bindings compile to plain,
efficient JS calls into any npm package.

- **Good:** Keeps ~90% of Elm's safety in the domain/application core while
  making the infrastructure adapters (IndexedDB, camera, service worker,
  Stripe) typed, direct, and testable rather than boxed behind a foreign
  message protocol — the interop layer is exactly where this app's real risk
  lives, so this is the more relevant guarantee. `rescript-react` gives a
  usable, reasonably mature view layer; Vite tooling and PWA plugins remain
  JS/TS and integrate normally at the build level.
- **Bad:** Smaller community and hiring/contributor pool than TypeScript
  (mitigated: no hiring constraint, and NFR-10's contributor goal is a soft
  target, not a hard one); steeper learning curve for OSS contributors used
  to plain JS/TS; fewer pre-built component libraries than the React/Solid ecosystem.

### Option 4: PureScript

Haskell-grade type system, same "no null / exhaustive matching" family as Elm/ReScript.

- **Good:** Even stronger type-system guarantees than ReScript (higher-kinded
  types, typeclasses) if the team wants to push further into pure-FP territory.
- **Bad:** No material upside over ReScript for this app's needs, smaller
  community than even Elm or ReScript, steepest learning curve of the four —
  dismissed without a deeper spike.

## Decision

**ReScript**, with `rescript-react` for the view layer, Vite for the build/PWA
tooling, and the hexagonal split from [[0002]] used deliberately: domain and
application code is plain ReScript (no JS interop, fully covered by the
compiler's guarantees), while infrastructure adapters (IndexedDB, barcode
camera capture, service worker registration, Verified-DB API client, Stripe
checkout) are the only code that touches ReScript's JS interop layer — kept
thin and covered by the boundary-validation strategy in [[0003]].

Rationale: the stated priority is a runtime-error-free app, and this app's
actual defect surface is dominated by browser-API interop rather than pure
logic. Elm's ports would push that exact interop code outside its safety
guarantee; ReScript keeps near-Elm-level guarantees for the domain/application
core while treating the interop surface as first-class, typed, directly
testable code — which is where the real risk, and therefore the real value of
"rock solid," actually lives.

This decision is **Proposed**, not Accepted — it should be revisited after a
spike validates `rescript-react` + `vite-plugin-pwa` interop and iOS Safari PWA
behavior (camera access, persistent storage, service worker lifecycle), per
the SRS §7 risk "iOS Safari PWA limitations."

## Consequences

### Positive

- Domain/application layer ([[0002]]) gets compiler-enforced exhaustiveness
  and no-null guarantees for the coaching/adjustment math the product's trust
  story depends on (FR-D-4 explainability)
- Infrastructure adapters are still typed and direct (no ports/message
  boundary), keeping camera/IndexedDB/Stripe/service-worker code testable
  with the same rigor as the domain core
- Smaller runtime than a virtual-DOM framework, helping the ≤2 MB gzipped shell budget (NFR-3)

### Negative / Trade-offs

- Smaller contributor pool and fewer pre-built UI components/examples than
  the TypeScript ecosystem — more infrastructure code written from scratch
  during M1/M2, raising short-term velocity risk against the SRS roadmap
- `rescript-react` and PWA plugin interop are less battle-tested than plain
  TS+React/Solid; expect more first-party test coverage to reach the same confidence

### Risks

- If the M1 spike shows `rescript-react` + PWA tooling interop is too rough
  (build integration, HMR, iOS Safari quirks), this decision should flip to
  Option 1 (TypeScript + Solid) before M2 logging-core work starts
- A smaller OSS contributor pool partially works against the NFR-10 goal of
  ≥10 external contributors, even though hiring itself isn't a project constraint

## Links

- Related: [ADR-0002](0002-adopt-hexagonal-architecture-for-the-spa-client.md)
- Related: [ADR-0003](0003-runtime-safety-strategy-strict-typescript-plus-boundary-validation.md)
- Source: `srs-macrotracker-mvp.md` §1.4, §2.3, §5 (NFR-1..4, NFR-10..12), §7
