open Vitest

let line = (id, name) =>
  `{"id":"${id}","name_en":"${name}","provenance_badge":"open_data","kcal_100g":130,"protein_100g":2.7,"carbs_100g":28,"fat_100g":0.3}`

testAsync("ingests decoded foods into the repository and reports counts", async () => {
  let stored = ref([])
  let repository: FoodRepository.t = {
    upsertMany: async foods => stored := foods,
    searchByName: async _ => [],
    count: async () => 0,
    remove: async _ => (),
    all: async () => stored.contents,
  }

  let ndjson = [line("1", "Rice"), `garbage`, line("2", "Beans")]->Array.join("\n")
  let report = await IngestBundle.run(~fetchText=() => Promise.resolve(ndjson), ~repository)

  expect(report.ingested)->toBe(2)
  expect(report.rejected)->toBe(1)
  expect(Array.length(stored.contents))->toBe(2)
})
