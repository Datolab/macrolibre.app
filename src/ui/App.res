// The M1/M2 shell: on first run the open base dataset is ingested into
// IndexedDB automatically; then the user searches, picks a food, logs a
// quantity, and sees today's running macro totals. Orchestration lives in the
// use cases and ports — this rescript-react adapter just drives them.

let bundleUrl = "/sample-open-base.ndjson.gz"

@val @scope("crypto") external randomUUID: unit => string = "randomUUID"
@val @scope("Date") external now: unit => float = "now"

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
  let (unit, setUnit) = React.useState(() => PortionUnit.Grams)
  let (todayEntries, setTodayEntries) = React.useState(() => ([]: array<LogEntry.t>))
  let (drawerOpen, setDrawerOpen) = React.useState(() => false)
  let profileStore = LocalStorageProfileStore.make()
  let (profile, setProfile) = React.useState(() => (None: option<Profile.t>))
  let (editingId, setEditingId) = React.useState(() => (None: option<string>))
  let (editGrams, setEditGrams) = React.useState(() => "")
  let (recent, setRecent) = React.useState(() => ([]: array<LogEntry.t>))
  let (showCustom, setShowCustom) = React.useState(() => false)
  let (showScanner, setShowScanner) = React.useState(() => false)
  let (showRawAdd, setShowRawAdd) = React.useState(() => false)
  let (scanStatus, setScanStatus) = React.useState(() => "")
  let barcodeLookup = OffBarcodeLookup.make()
  let (templateRepo, setTemplateRepo) = React.useState(() => (None: option<TemplateRepository.t>))
  let (templates, setTemplates) = React.useState(() => ([]: array<MealTemplate.t>))
  // None = not composing a template; Some(items) = building one, accumulating items.
  let (building, setBuilding) = React.useState(() => (None: option<array<MealTemplate.item>>))
  let (templateName, setTemplateName) = React.useState(() => "")

  let refreshTemplates = (repo: TemplateRepository.t) =>
    repo.listAll()->Promise.thenResolve(ts => setTemplates(_ => ts))->ignore

  // Refresh both log-derived views (today's entries + the quick-add recents).
  let refreshToday = (logRepo: LogRepository.t) => {
    logRepo.listByDay(todayKey())->Promise.thenResolve(e => setTodayEntries(_ => e))->ignore
    logRepo.recent(8)->Promise.thenResolve(r => setRecent(_ => r))->ignore
  }

  // Boot: open repositories, auto-ingest the dataset on first run, load today.
  React.useEffect0(() => {
    (
      async () => {
        let foodRepo = await IndexedDbFoodRepository.make()
        let logRepo = await IndexedDbLogRepository.make()
        let templRepo = await IndexedDbTemplateRepository.make()
        setFoods(_ => Some(foodRepo))
        setLogs(_ => Some(logRepo))
        setTemplateRepo(_ => Some(templRepo))

        let existing = await foodRepo.count()
        if existing == 0 {
          setBootMsg(_ => "Downloading food database…")
          let text = await BundleFetcher.fetchBundle(bundleUrl)
          let decoded = BundleDecoder.decodeNdjson(text)
          await foodRepo.upsertMany(decoded.foods)
        }
        let entries = await logRepo.listByDay(todayKey())
        setTodayEntries(_ => entries)
        let recentFoods = await logRepo.recent(8)
        setRecent(_ => recentFoods)
        let savedTemplates = await templRepo.listAll()
        setTemplates(_ => savedTemplates)
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
      | Some(q) if q > 0. =>
        let g = PortionUnit.toGrams(unit, q)
        LogFood.run(
          ~repository=logRepo,
          ~id=randomUUID(),
          ~food,
          ~grams=g,
          ~day=todayKey(),
          ~loggedAt=now(),
        )
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

  // Template building: accumulate {food, grams} as a template item, using the
  // same search/select/grams picker as logging, instead of logging it now.
  let addItemToBuilding = (food: Food.t) =>
    switch (building, Float.fromString(grams)) {
    | (Some(items), Some(q)) if q > 0. =>
      let g = PortionUnit.toGrams(unit, q)
      let item: MealTemplate.item = {
        foodId: food.id,
        foodName: food.nameEn,
        grams: g,
        macros: Macros.forQuantity(food, g),
      }
      setBuilding(_ => Some(Array.concat(items, [item])))
      setSelected(_ => None)
      setQuery(_ => "")
      setResults(_ => [])
    | _ => ()
    }

  let removeBuildingItem = index =>
    switch building {
    | Some(items) => setBuilding(_ => Some(items->Array.filterWithIndex((_, i) => i != index)))
    | None => ()
    }

  let startBuilding = () => setBuilding(_ => Some([]))

  let cancelBuilding = () => {
    setBuilding(_ => None)
    setTemplateName(_ => "")
  }

  let saveTemplate = () =>
    switch (building, templateRepo) {
    | (Some(items), Some(repo)) if Array.length(items) > 0 && templateName->String.trim != "" =>
      let template: MealTemplate.t = {id: randomUUID(), name: templateName->String.trim, items}
      repo
      .add(template)
      ->Promise.thenResolve(_ => {
        setBuilding(_ => None)
        setTemplateName(_ => "")
        refreshTemplates(repo)
      })
      ->ignore
    | _ => ()
    }

  // Log every item of a saved template to today in one action (FR-A).
  let logTemplate = (template: MealTemplate.t) =>
    switch logs {
    | Some(logRepo) =>
      LogMealTemplate.run(
        ~repository=logRepo,
        ~template,
        ~ids=template.items->Array.map(_ => randomUUID()),
        ~day=todayKey(),
        ~loggedAt=now(),
      )
      ->Promise.thenResolve(_ => refreshToday(logRepo))
      ->ignore
    | None => ()
    }

  let deleteTemplate = id =>
    switch templateRepo {
    | Some(repo) => repo.remove(id)->Promise.thenResolve(_ => refreshTemplates(repo))->ignore
    | None => ()
    }

  // Quick-add: re-log a recent food at its last quantity in one tap.
  let relog = (entry: LogEntry.t) =>
    switch logs {
    | Some(logRepo) =>
      logRepo.add({...entry, id: randomUUID(), day: todayKey(), loggedAt: now()})
      ->Promise.thenResolve(_ => refreshToday(logRepo))
      ->ignore
    | None => ()
    }

  // A scanned barcode: look it up online (OFF), cache it in foods_local, and
  // select it ready to log. Not found -> a message.
  let onBarcode = barcode => {
    setShowScanner(_ => false)
    setScanStatus(_ => "Looking up…")
    barcodeLookup.lookup(barcode)
    ->Promise.thenResolve(result =>
      switch (result, foods) {
      | (Some(food), Some(foodRepo)) =>
        foodRepo.upsertMany([food])
        ->Promise.thenResolve(_ => {
          setScanStatus(_ => "")
          setSelected(_ => Some(food))
        })
        ->ignore
      | (None, _) => setScanStatus(_ => `No product found for barcode ${barcode}`)
      | _ => ()
      }
    )
    ->ignore
  }

  let removeEntry = id =>
    switch logs {
    | Some(logRepo) => logRepo.remove(id)->Promise.thenResolve(_ => refreshToday(logRepo))->ignore
    | None => ()
    }

  let startEdit = (entry: LogEntry.t) => {
    setEditingId(_ => Some(entry.id))
    setEditGrams(_ => entry.grams->round)
  }

  let saveEdit = (entry: LogEntry.t) =>
    switch (logs, Float.fromString(editGrams)) {
    | (Some(logRepo), Some(g)) if g > 0. =>
      logRepo.add(LogEntry.rescale(entry, g))
      ->Promise.thenResolve(_ => {
        setEditingId(_ => None)
        refreshToday(logRepo)
      })
      ->ignore
    | _ => ()
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
            {Array.length(recent) == 0
              ? React.null
              : <div className="quick-add">
                  <h2> {React.string("Quick add")} </h2>
                  <div className="chips">
                    {recent
                    ->Array.map((entry: LogEntry.t) =>
                      <button key={entry.id} className="chip" onClick={_ => relog(entry)}>
                        {React.string(`${entry.foodName} · ${entry.grams->round} g`)}
                      </button>
                    )
                    ->React.array}
                  </div>
                </div>}
            <div className="templates">
              <h2> {React.string("Templates")} </h2>
              {Array.length(templates) == 0
                ? React.null
                : <div className="chips">
                    {templates
                    ->Array.map((template: MealTemplate.t) =>
                      <span key={template.id} className="chip-group">
                        <button className="chip" onClick={_ => logTemplate(template)}>
                          {React.string(`▤ ${template.name}`)}
                        </button>
                        <button
                          className="link danger"
                          ariaLabel={`Delete ${template.name}`}
                          onClick={_ => deleteTemplate(template.id)}>
                          {React.string("✕")}
                        </button>
                      </span>
                    )
                    ->React.array}
                  </div>}
              {switch building {
              | None =>
                <button className="link" onClick={_ => startBuilding()}>
                  {React.string("+ New template")}
                </button>
              | Some(items) =>
                <div className="template-builder">
                  <p> {React.string("Search a food below and add it to this template.")} </p>
                  <ul>
                    {items
                    ->Array.mapWithIndex((item: MealTemplate.item, i) =>
                      <li key={`${item.foodId}-${i->Int.toString}`}>
                        <span>
                          {React.string(`${item.foodName} — ${item.grams->round} g`)}
                        </span>
                        <button
                          className="link danger" ariaLabel="Remove" onClick={_ => removeBuildingItem(i)}>
                          {React.string("✕")}
                        </button>
                      </li>
                    )
                    ->React.array}
                  </ul>
                  <input
                    placeholder="Template name (e.g. Breakfast)"
                    value={templateName}
                    onChange={e => setTemplateName(_ => (e->ReactEvent.Form.target)["value"])}
                  />
                  <button className="primary" onClick={_ => saveTemplate()}>
                    {React.string("Save template")}
                  </button>
                  <button className="link" onClick={_ => cancelBuilding()}>
                    {React.string("Cancel")}
                  </button>
                </div>
              }}
            </div>
            <input type_="search" placeholder="Search foods…" value={query} onChange={onSearch} />
            {showScanner
              ? <BarcodeScanner onDetected={onBarcode} onClose={() => setShowScanner(_ => false)} />
              : showCustom
              ? <CustomFoodForm
                  onCancel={() => setShowCustom(_ => false)}
                  onSave={food =>
                    switch foods {
                    | Some(foodRepo) =>
                      foodRepo.upsertMany([food])
                      ->Promise.thenResolve(_ => {
                        setShowCustom(_ => false)
                        setQuery(_ => "")
                        setResults(_ => [])
                        setSelected(_ => Some(food)) // ready to log right away
                      })
                      ->ignore
                    | None => ()
                    }}
                />
              : showRawAdd
              ? <RawMacroForm
                  day={todayKey()}
                  onCancel={() => setShowRawAdd(_ => false)}
                  onSave={entry =>
                    switch logs {
                    | Some(logRepo) =>
                      logRepo.add(entry)
                      ->Promise.thenResolve(_ => {
                        setShowRawAdd(_ => false)
                        refreshToday(logRepo)
                      })
                      ->ignore
                    | None => ()
                    }}
                />
              : <>
                  <div className="search-actions">
                    <button className="link" onClick={_ => setShowScanner(_ => true)}>
                      {React.string("▣ Scan barcode")}
                    </button>
                    <button className="link" onClick={_ => setShowCustom(_ => true)}>
                      {React.string("＋ Add a custom food")}
                    </button>
                    {building == None
                      ? <button className="link" onClick={_ => setShowRawAdd(_ => true)}>
                          {React.string("⌁ Quick-add macros")}
                        </button>
                      : React.null}
                  </div>
                  {scanStatus == "" ? React.null : <p className="scan-status"> {React.string(scanStatus)} </p>}
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
                </>}
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
                <select
                  value={unit->PortionUnit.label}
                  onChange={e => {
                    let v = (e->ReactEvent.Form.target)["value"]
                    setUnit(_ => v == "oz" ? PortionUnit.Ounces : PortionUnit.Grams)
                  }}>
                  <option value="g"> {React.string("g")} </option>
                  <option value="oz"> {React.string("oz")} </option>
                </select>
                {switch building {
                | Some(_) =>
                  <button className="primary" onClick={_ => addItemToBuilding(food)}>
                    {React.string("Add to template")}
                  </button>
                | None =>
                  <button className="primary" onClick={_ => addToday(food)}>
                    {React.string("Add to today")}
                  </button>
                }}
              </div>
            }}
            <h2> {React.string("Today")} </h2>
            <ul>
              {todayEntries
              ->Array.map((entry: LogEntry.t) =>
                <li key={entry.id}>
                  {editingId == Some(entry.id)
                    ? <div className="logged edit-row">
                        <input
                          type_="number"
                          value={editGrams}
                          onChange={e => setEditGrams(_ => (e->ReactEvent.Form.target)["value"])}
                        />
                        {React.string(" g ")}
                        <button className="primary" onClick={_ => saveEdit(entry)}>
                          {React.string("Save")}
                        </button>
                        <button className="link" onClick={_ => setEditingId(_ => None)}>
                          {React.string("Cancel")}
                        </button>
                      </div>
                    : <div className="logged log-row">
                        <span>
                          {React.string(
                            `${entry.foodName} — ${entry.grams->round} g · ${entry.macros.kcal->round} kcal`,
                          )}
                        </span>
                        <span className="row-actions">
                          <button className="link" onClick={_ => startEdit(entry)}>
                            {React.string("Edit")}
                          </button>
                          <button
                            className="link danger"
                            ariaLabel="Remove"
                            onClick={_ => removeEntry(entry.id)}>
                            {React.string("✕")}
                          </button>
                        </span>
                      </div>}
                </li>
              )
              ->React.array}
            </ul>
          </main>
        }}
    <Drawer isOpen={drawerOpen} onClose={() => setDrawerOpen(_ => false)} />
  </>
}
