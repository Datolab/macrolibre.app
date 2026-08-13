open Vitest

%%raw(`import "fake-indexeddb/auto"`)

testAsync("records weigh-ins and lists them all", async () => {
  let repo = await IndexedDbWeightRepository.make()
  await repo.record({WeightEntry.day: "2026-11-01", kg: 80.5, loggedAt: 100.})
  await repo.record({WeightEntry.day: "2026-11-02", kg: 80.2, loggedAt: 200.})

  let all = await repo.listAll()
  let nov1 = all->Array.find(w => w.day == "2026-11-01")
  let nov2 = all->Array.find(w => w.day == "2026-11-02")
  expect(nov1->Option.map(w => w.kg))->toEqual(Some(80.5))
  expect(nov2->Option.map(w => w.kg))->toEqual(Some(80.2))
})

testAsync("a second weigh-in on the same day replaces the first", async () => {
  let repo = await IndexedDbWeightRepository.make()
  await repo.record({WeightEntry.day: "2026-12-01", kg: 90., loggedAt: 100.})
  await repo.record({WeightEntry.day: "2026-12-01", kg: 89.5, loggedAt: 200.})

  let all = await repo.listAll()
  let dec1Entries = all->Array.filter(w => w.day == "2026-12-01")
  expect(Array.length(dec1Entries))->toBe(1)
  expect((dec1Entries->Array.getUnsafe(0)).kg)->toBe(89.5)
})
