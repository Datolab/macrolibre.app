open Vitest

let food: Food.t = {
  id: "f1",
  nameEn: "Rice",
  nameEs: None,
  region: None,
  provenance: Food.OpenData,
  kcal100g: 130.,
  protein100g: 2.7,
  carbs100g: 28.,
  fat100g: 0.3,
}

testAsync("logs a food with macros scaled to the quantity", async () => {
  let added = ref([])
  let repository: LogRepository.t = {
    add: async entry => added := Array.concat(added.contents, [entry]),
    listByDay: async _ => [],
    remove: async _ => (),
    recent: async _ => [],
  }

  let entry = await LogFood.run(
    ~repository,
    ~id="e1",
    ~food,
    ~grams=200.,
    ~day="2026-08-07",
    ~loggedAt=1000.,
  )

  expect(entry.macros.kcal)->toBe(260.) // 130 * 200/100
  expect(entry.foodName)->toBe("Rice")
  expect(entry.grams)->toBe(200.)
  expect(Array.length(added.contents))->toBe(1)
})
