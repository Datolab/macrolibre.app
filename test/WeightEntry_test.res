open Vitest

test("builds a valid weigh-in", () => {
  switch WeightEntry.build(~kg=72.4, ~day="2026-08-13", ~loggedAt=1000.) {
  | Some(entry) => {
      expect(entry.kg)->toBe(72.4)
      expect(entry.day)->toBe("2026-08-13")
      expect(entry.loggedAt)->toBe(1000.)
    }
  | None => expect(false)->toBe(true)
  }
})

test("rejects a negative, zero, or non-finite weight", () => {
  let zero = WeightEntry.build(~kg=0., ~day="2026-08-13", ~loggedAt=0.)
  let negative = WeightEntry.build(~kg=-5., ~day="2026-08-13", ~loggedAt=0.)
  let nan = WeightEntry.build(~kg=Float.Constants.nan, ~day="2026-08-13", ~loggedAt=0.)
  expect(zero->Option.isNone)->toBe(true)
  expect(negative->Option.isNone)->toBe(true)
  expect(nan->Option.isNone)->toBe(true)
})
