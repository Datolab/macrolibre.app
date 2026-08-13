open Vitest

test("builds a logged entry from raw macros, defaulting a blank name", () => {
  switch RawLogEntry.build(
    ~id="e1",
    ~name="   ",
    ~kcal=350.,
    ~protein=20.,
    ~carbs=40.,
    ~fat=10.,
    ~day="2026-08-13",
    ~loggedAt=1000.,
  ) {
  | Some(entry) => {
      expect(entry.foodName)->toBe("Quick add")
      expect(entry.macros.kcal)->toBe(350.)
      expect(entry.macros.protein)->toBe(20.)
      expect(entry.day)->toBe("2026-08-13")
      expect(entry.loggedAt)->toBe(1000.)
      expect(entry.id)->toBe("e1")
    }
  | None => expect(false)->toBe(true)
  }
})

test("keeps a trimmed custom label when one is given", () => {
  switch RawLogEntry.build(
    ~id="e2",
    ~name=" Restaurant meal ",
    ~kcal=600.,
    ~protein=30.,
    ~carbs=50.,
    ~fat=25.,
    ~day="2026-08-13",
    ~loggedAt=1000.,
  ) {
  | Some(entry) => expect(entry.foodName)->toBe("Restaurant meal")
  | None => expect(false)->toBe(true)
  }
})

test("rejects a negative or non-finite macro", () => {
  let negative = RawLogEntry.build(
    ~id="e3",
    ~name="x",
    ~kcal=-1.,
    ~protein=1.,
    ~carbs=1.,
    ~fat=1.,
    ~day="2026-08-13",
    ~loggedAt=0.,
  )
  let nan = RawLogEntry.build(
    ~id="e4",
    ~name="x",
    ~kcal=Float.Constants.nan,
    ~protein=1.,
    ~carbs=1.,
    ~fat=1.,
    ~day="2026-08-13",
    ~loggedAt=0.,
  )
  expect(negative->Option.isNone)->toBe(true)
  expect(nan->Option.isNone)->toBe(true)
})
