open Vitest

let template: MealTemplate.t = {
  id: "tmpl1",
  name: "Breakfast",
  items: [
    {foodId: "f1", foodName: "Rice", grams: 100., macros: {Macros.kcal: 130., protein: 2.7, carbs: 28., fat: 0.3}},
    {foodId: "f2", foodName: "Egg", grams: 50., macros: {Macros.kcal: 78., protein: 6.5, carbs: 0.6, fat: 5.3}},
  ],
}

testAsync("logs one entry per template item, using each item's saved macros", async () => {
  let added = ref([])
  let repository: LogRepository.t = {
    add: async entry => added := Array.concat(added.contents, [entry]),
    listByDay: async _ => [],
    remove: async _ => (),
    recent: async _ => [],
  }

  let entries = await LogMealTemplate.run(
    ~repository,
    ~template,
    ~ids=["e1", "e2"],
    ~day="2026-08-10",
    ~loggedAt=1000.,
  )

  expect(Array.length(entries))->toBe(2)
  expect(Array.length(added.contents))->toBe(2)
  expect((entries->Array.getUnsafe(0)).foodName)->toBe("Rice")
  expect((entries->Array.getUnsafe(0)).macros.kcal)->toBe(130.)
  expect((entries->Array.getUnsafe(1)).foodName)->toBe("Egg")
  expect((entries->Array.getUnsafe(0)).day)->toBe("2026-08-10")
  expect((entries->Array.getUnsafe(0)).loggedAt)->toBe(1000.)
  expect((entries->Array.getUnsafe(0)).id)->toBe("e1")
  expect((entries->Array.getUnsafe(1)).id)->toBe("e2")
})
