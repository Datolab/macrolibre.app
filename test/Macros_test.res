open Vitest

let food = (kcal, protein, carbs, fat): Food.t => {
  id: "x",
  nameEn: "x",
  nameEs: None,
  region: None,
  provenance: Food.OpenData,
  kcal100g: kcal,
  protein100g: protein,
  carbs100g: carbs,
  fat100g: fat,
}

test("scales per-100g macros to a logged quantity", () => {
  let m = Macros.forQuantity(food(200., 10., 20., 5.), 50.)
  expect(m.kcal)->toBe(100.)
  expect(m.protein)->toBe(5.)
  expect(m.carbs)->toBe(10.)
})

test("sums a day's macros", () => {
  let total = Macros.sum([
    {Macros.kcal: 100., protein: 5., carbs: 10., fat: 2.},
    {Macros.kcal: 50., protein: 2., carbs: 5., fat: 1.},
  ])
  expect(total.kcal)->toBe(150.)
  expect(total.protein)->toBe(7.)
})
