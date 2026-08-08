open Vitest

// Polyfill IndexedDB + IDBKeyRange in node so the adapter can be tested headless.
%%raw(`import "fake-indexeddb/auto"`)

let food = (id, nameEn): Food.t => {
  id,
  nameEn,
  nameEs: None,
  region: None,
  provenance: Food.OpenData,
  kcal100g: 0.,
  protein100g: 0.,
  carbs100g: 0.,
  fat100g: 0.,
}

testAsync("upserts foods and finds them by normalized name prefix", async () => {
  let repo = await IndexedDbFoodRepository.make()
  await repo.upsertMany([food("1", "Black Beans"), food("2", "Rice")])

  // Case-insensitive prefix: query "black" matches stored key "black beans".
  let results = await repo.searchByName("BLACK")
  expect(Array.length(results))->toBe(1)
  expect((results->Array.getUnsafe(0)).nameEn)->toBe("Black Beans")
})

testAsync("matches a non-leading word via the token index", async () => {
  let repo = await IndexedDbFoodRepository.make()
  await repo.upsertMany([food("t1", "Corn Tortilla"), food("t2", "White Rice")])

  // "tort" is not a prefix of the whole name, but is a prefix of a token.
  let results = await repo.searchByName("tort")
  expect(Array.length(results))->toBe(1)
  expect((results->Array.getUnsafe(0)).nameEn)->toBe("Corn Tortilla")
})
