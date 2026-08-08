open Vitest

let entry: LogEntry.t = {
  id: "1",
  foodName: "Rice",
  grams: 100.,
  macros: {Macros.kcal: 130., protein: 2.7, carbs: 28., fat: 0.3},
  day: "2026-08-07",
}

test("rescales macros proportionally when the grams change", () => {
  let updated = LogEntry.rescale(entry, 200.)
  expect(updated.grams)->toBe(200.)
  expect(updated.macros.kcal)->toBe(260.)
  expect(updated.macros.protein)->toBe(5.4)
  expect(updated.id)->toBe("1") // same entry, upserted in place
})
