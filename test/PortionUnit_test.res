open Vitest

test("grams pass through unchanged", () => {
  expect(PortionUnit.toGrams(PortionUnit.Grams, 150.))->toBe(150.)
})

test("converts ounces to grams", () => {
  expect(PortionUnit.toGrams(PortionUnit.Ounces, 1.))->toBe(28.3495)
})

test("labels each unit for display", () => {
  expect(PortionUnit.label(PortionUnit.Grams))->toBe("g")
  expect(PortionUnit.label(PortionUnit.Ounces))->toBe("oz")
})
