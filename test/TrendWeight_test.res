open Vitest

test("seeds the trend at the first observed weight", () => {
  expect(TrendWeight.step(~previous=None, ~observedKg=80.))->toBe(80.)
})

test("smooths subsequent observations toward the new value by alpha", () => {
  // previous 80, observed 82, alpha 0.1 -> 80 + 0.1*(82-80) = 80.2
  expect(TrendWeight.step(~previous=Some(80.), ~observedKg=82.))->toBe(80.2)
})

test("accepts a custom alpha", () => {
  // previous 80, observed 82, alpha 0.5 -> 80 + 0.5*(82-80) = 81
  expect(TrendWeight.step(~previous=Some(80.), ~observedKg=82., ~alpha=0.5))->toBe(81.)
})

test("folds a day-ordered series into cumulative trend values", () => {
  let entries: array<WeightEntry.t> = [
    {day: "2026-08-01", kg: 80., loggedAt: 0.},
    {day: "2026-08-02", kg: 82., loggedAt: 0.},
    {day: "2026-08-03", kg: 82., loggedAt: 0.},
  ]
  let trend = TrendWeight.series(entries)
  expect(Array.length(trend))->toBe(3)
  let (day1, kg1) = trend->Array.getUnsafe(0)
  let (day2, kg2) = trend->Array.getUnsafe(1)
  expect(day1)->toBe("2026-08-01")
  expect(kg1)->toBe(80.)
  expect(day2)->toBe("2026-08-02")
  expect(kg2)->toBe(80.2)
})
