open Vitest

%%raw(`import "fake-indexeddb/auto"`)

let entry = (id, day): LogEntry.t => {
  id,
  foodName: "Rice",
  grams: 100.,
  macros: {Macros.kcal: 130., protein: 2.7, carbs: 28., fat: 0.3},
  day,
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
