open Vitest

test("builds a valid custom food, trimmed and marked user-submitted", () => {
  switch CustomFood.build(~id="x", ~name="  My snack ", ~kcal=200., ~protein=10., ~carbs=20., ~fat=5.) {
  | Some(food) => {
      expect(food.nameEn)->toBe("My snack")
      expect(food.provenance)->toEqual(Food.UserSubmitted)
      expect(food.kcal100g)->toBe(200.)
    }
  | None => expect(false)->toBe(true)
  }
})

test("rejects an empty name or a negative/non-finite macro", () => {
  let blankName = CustomFood.build(~id="x", ~name="   ", ~kcal=1., ~protein=1., ~carbs=1., ~fat=1.)
  let negative = CustomFood.build(~id="x", ~name="ok", ~kcal=-1., ~protein=1., ~carbs=1., ~fat=1.)
  let nan = CustomFood.build(~id="x", ~name="ok", ~kcal=Float.Constants.nan, ~protein=1., ~carbs=1., ~fat=1.)
  expect(blankName->Option.isNone)->toBe(true)
  expect(negative->Option.isNone)->toBe(true)
  expect(nan->Option.isNone)->toBe(true)
})
