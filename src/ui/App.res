// The M1/M2 shell: on first run the open base dataset is ingested into
// IndexedDB automatically; then the user searches, picks a food, logs a
// quantity, and sees today's running macro totals. Orchestration lives in the
// use cases and ports — this rescript-react adapter just drives them.

let bundleUrl = "/sample-open-base.ndjson.gz"

@val @scope("crypto") external randomUUID: unit => string = "randomUUID"

let todayKey = () => Date.make()->Date.toISOString->String.slice(~start=0, ~end=10)
let round = (f: float) => f->Math.round->Float.toString

@react.component
let make = () => {
  let (foods, setFoods) = React.useState(() => (None: option<FoodRepository.t>))
  let (logs, setLogs) = React.useState(() => (None: option<LogRepository.t>))
  let (booting, setBooting) = React.useState(() => true)
  let (bootMsg, setBootMsg) = React.useState(() => "Opening local database…")
  let (query, setQuery) = React.useState(() => "")
  let (results, setResults) = React.useState(() => ([]: array<Food.t>))
  let (selected, setSelected) = React.useState(() => (None: option<Food.t>))
  let (grams, setGrams) = React.useState(() => "100")
  let (todayEntries, setTodayEntries) = React.useState(() => ([]: array<LogEntry.t>))
  let (drawerOpen, setDrawerOpen) = React.useState(() => false)
  let profileStore = LocalStorageProfileStore.make()
  let (profile, setProfile) = React.useState(() => (None: option<Profile.t>))

  let refreshToday = (logRepo: LogRepository.t) =>
    logRepo.listByDay(todayKey())->Promise.thenResolve(e => setTodayEntries(_ => e))->ignore

  // Boot: open repositories, auto-ingest the dataset on first run, load today.
  React.useEffect0(() => {
    (
      async () => {
        let foodRepo = await IndexedDbFoodRepository.make()
        let logRepo = await IndexedDbLogRepository.make()
        setFoods(_ => Some(foodRepo))
        setLogs(_ => Some(logRepo))

        let existing = await foodRepo.count()
        if existing == 0 {
          setBootMsg(_ => "Downloading food database…")
          let text = await BundleFetcher.fetchBundle(bundleUrl)
          let decoded = BundleDecoder.decodeNdjson(text)
          await foodRepo.upsertMany(decoded.foods)
        }
        let entries = await logRepo.listByDay(todayKey())
        setTodayEntries(_ => entries)
        setProfile(_ => profileStore.load())
        setBooting(_ => false)
      }
    )()->ignore
    None
  })

  let onSearch = event => {
    let value = (event->ReactEvent.Form.target)["value"]
    setQuery(_ => value)
    setSelected(_ => None)
    switch foods {
    | None => ()
    | Some(repo) => repo.searchByName(value)->Promise.thenResolve(fs => setResults(_ => fs))->ignore
    }
  }

  let addToday = (food: Food.t) =>
    switch logs {
    | None => ()
    | Some(logRepo) =>
      switch Float.fromString(grams) {
      | Some(g) if g > 0. =>
        LogFood.run(~repository=logRepo, ~id=randomUUID(), ~food, ~grams=g, ~day=todayKey())
        ->Promise.thenResolve(_ => {
          setSelected(_ => None)
          setQuery(_ => "")
          setResults(_ => [])
          refreshToday(logRepo)
        })
        ->ignore
      | _ => ()
      }
    }

  let total = Macros.sum(todayEntries->Array.map(e => e.macros))

  <>
    <Header onMenu={() => setDrawerOpen(_ => true)} />
    {booting
      ? <main> <p> {React.string(bootMsg)} </p> </main>
      : switch profile {
        | None =>
          <Onboarding
            onComplete={p => {
              profileStore.save(p)
              setProfile(_ => Some(p))
            }}
          />
        | Some(p) =>
          <main>
            <MacroRings
              consumed={total}
              targets={MacroTargets.fromCalories(p.kcalGoal)}
              calorieGoal={p.kcalGoal}
            />
            <input type_="search" placeholder="Search foods…" value={query} onChange={onSearch} />
            <ul>
              {results
              ->Array.map((food: Food.t) =>
                <li key={food.id}>
                  <button className="food-row" onClick={_ => setSelected(_ => Some(food))}>
                    {React.string(`${food.nameEn} — ${food.kcal100g->round} kcal/100 g`)}
                  </button>
                </li>
              )
              ->React.array}
            </ul>
            {switch selected {
            | None => React.null
            | Some(food) =>
              <div className="add">
                <span> {React.string(`Add ${food.nameEn}: `)} </span>
                <input
                  type_="number"
                  value={grams}
                  onChange={e => setGrams(_ => (e->ReactEvent.Form.target)["value"])}
                />
                {React.string(" g ")}
                <button className="primary" onClick={_ => addToday(food)}>
                  {React.string("Add to today")}
                </button>
              </div>
            }}
            <h2> {React.string("Today")} </h2>
            <ul>
              {todayEntries
              ->Array.map((entry: LogEntry.t) =>
                <li key={entry.id}>
                  <div className="logged">
                    {React.string(
                      `${entry.foodName} — ${entry.grams->round} g · ${entry.macros.kcal->round} kcal`,
                    )}
                  </div>
                </li>
              )
              ->React.array}
            </ul>
          </main>
        }}
    <Drawer isOpen={drawerOpen} onClose={() => setDrawerOpen(_ => false)} />
  </>
}
