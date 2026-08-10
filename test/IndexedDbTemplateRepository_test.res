open Vitest

%%raw(`import "fake-indexeddb/auto"`)

let template = (id, name): MealTemplate.t => {
  id,
  name,
  items: [
    {
      MealTemplate.foodId: "f1",
      foodName: "Rice",
      grams: 100.,
      macros: {Macros.kcal: 130., protein: 2.7, carbs: 28., fat: 0.3},
    },
    {
      MealTemplate.foodId: "f2",
      foodName: "Egg",
      grams: 50.,
      macros: {Macros.kcal: 78., protein: 6.5, carbs: 0.6, fat: 5.3},
    },
  ],
}

testAsync("adds templates and lists them all, items intact", async () => {
  let repo = await IndexedDbTemplateRepository.make()
  await repo.add(template("t1", "Breakfast"))
  await repo.add(template("t2", "Lunch"))

  let all = await repo.listAll()
  expect(Array.length(all))->toBe(2)
  let breakfast = all->Array.find(t => t.id == "t1")
  expect(breakfast->Option.map(t => t.name))->toEqual(Some("Breakfast"))
  expect(breakfast->Option.map(t => Array.length(t.items)))->toEqual(Some(2))
  let firstItem = breakfast->Option.flatMap(t => t.items->Array.get(0))
  expect(firstItem->Option.map(i => i.foodName))->toEqual(Some("Rice"))
  expect(firstItem->Option.map(i => i.macros.kcal))->toEqual(Some(130.))
})

testAsync("removes a template by id", async () => {
  let repo = await IndexedDbTemplateRepository.make()
  await repo.add(template("keep", "Breakfast"))
  await repo.add(template("drop", "Lunch"))
  await repo.remove("drop")

  let all = await repo.listAll()
  expect(all->Array.some(t => t.id == "keep"))->toBe(true)
  expect(all->Array.some(t => t.id == "drop"))->toBe(false)
})
