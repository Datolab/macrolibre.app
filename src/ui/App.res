// The M1 shell: load the open base dataset into IndexedDB, then search it
// locally. A driving adapter (rescript-react) — orchestration lives in the
// IngestBundle use case and the FoodRepository port, not here.

let bundleUrl = "/sample-open-base.ndjson.gz"

@react.component
let make = () => {
  let (repository, setRepository) = React.useState(() => None)
  let (status, setStatus) = React.useState(() => "")
  let (query, setQuery) = React.useState(() => "")
  let (results, setResults) = React.useState((): array<Food.t> => [])

  // Open the IndexedDB repository once, on mount.
  React.useEffect0(() => {
    IndexedDbFoodRepository.make()
    ->Promise.thenResolve(repo => setRepository(_ => Some(repo)))
    ->ignore
    None
  })

  let loadDataset = repo => {
    setStatus(_ => "Loading…")
    IngestBundle.run(~fetchText=() => BundleFetcher.fetchBundle(bundleUrl), ~repository=repo)
    ->Promise.thenResolve(report =>
      setStatus(_ =>
        `Loaded ${report.ingested->Int.toString} foods` ++
        (report.rejected > 0 ? ` (${report.rejected->Int.toString} skipped)` : "")
      )
    )
    ->Promise.catch(_ => {
      setStatus(_ => "Failed to load the dataset")
      Promise.resolve()
    })
    ->ignore
  }

  let onSearch = event => {
    let value = (event->ReactEvent.Form.target)["value"]
    setQuery(_ => value)
    switch repository {
    | None => ()
    | Some(repo) =>
      repo.searchByName(value)->Promise.thenResolve(foods => setResults(_ => foods))->ignore
    }
  }

  <main>
    <h1> {React.string("MacroLibre")} </h1>
    <p> {React.string("Local-first macro & nutrition tracker. Works offline, no account.")} </p>
    {switch repository {
    | None => <p> {React.string("Opening local database…")} </p>
    | Some(repo) =>
      <>
        <p>
          <button onClick={_ => loadDataset(repo)}> {React.string("Load open base dataset")} </button>
          {" " |> React.string}
          <span> {React.string(status)} </span>
        </p>
        <input type_="search" placeholder="Search foods…" value={query} onChange={onSearch} />
        <ul>
          {results
          ->Array.map((food: Food.t) =>
            <li key={food.id}>
              {React.string(`${food.nameEn} — ${food.kcal100g->Float.toString} kcal / 100 g`)}
            </li>
          )
          ->React.array}
        </ul>
      </>
    }}
  </main>
}
