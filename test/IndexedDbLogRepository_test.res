open Vitest

%%raw(`import "fake-indexeddb/auto"`)

let entry = (id, day): LogEntry.t => {
  id,
  foodName: "Rice",
  grams: 100.,
  macros: {Macros.kcal: 130., protein: 2.7, carbs: 28., fat: 0.3},
  day,
  loggedAt: 0.,
}

testAsync("adds entries and lists them by day", async () => {
  let repo = await IndexedDbLogRepository.make()
  await repo.add(entry("1", "2026-08-07"))
  await repo.add(entry("2", "2026-08-07"))
  await repo.add(entry("3", "2026-08-06"))

  let today = await repo.listByDay("2026-08-07")
  expect(Array.length(today))->toBe(2)
})

testAsync("removes an entry by id", async () => {
  let repo = await IndexedDbLogRepository.make()
  await repo.add(entry("keep", "2026-09-01"))
  await repo.add(entry("drop", "2026-09-01"))
  await repo.remove("drop")

  let remaining = await repo.listByDay("2026-09-01")
  expect(Array.length(remaining))->toBe(1)
  expect((remaining->Array.getUnsafe(0)).id)->toBe("keep")
})

testAsync("recent returns distinct foods, newest first, deduped to the latest", async () => {
  let repo = await IndexedDbLogRepository.make()
  let e = (id, name, at, grams): LogEntry.t => {
    id,
    foodName: name,
    grams,
    macros: {Macros.kcal: 1., protein: 0., carbs: 0., fat: 0.},
    day: "2026-10-01",
    loggedAt: at,
  }
  await repo.add(e("a1", "Apple", 100., 50.))
  await repo.add(e("b1", "Banana", 300., 120.))
  await repo.add(e("a2", "Apple", 500., 150.)) // most recent, wins for Apple

  let recent = await repo.recent(20)
  let names = recent->Array.map(x => x.foodName)
  // Apple appears once (deduped) and before Banana (more recent).
  expect(names->Array.filter(n => n == "Apple")->Array.length)->toBe(1)
  expect(names->Array.indexOf("Apple") < names->Array.indexOf("Banana"))->toBe(true)
  // The kept Apple is the latest one (150 g, not 50 g).
  let apple = recent->Array.find(x => x.foodName == "Apple")
  expect(apple->Option.map(x => x.grams))->toEqual(Some(150.))
})
