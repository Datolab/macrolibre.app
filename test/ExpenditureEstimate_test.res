open Vitest

test("implied TDEE equals average intake when weight is stable", () => {
  let result = ExpenditureEstimate.compute(
    ~totalKcalLogged=14000.,
    ~daysLogged=7,
    ~weightChangeKg=0.,
    ~days=7,
  )
  expect(result.avgDailyIntakeKcal)->toBe(2000.)
  expect(result.impliedTdeeKcal)->toBe(2000.)
})

test("a weight loss implies a higher TDEE than average intake", () => {
  // -0.5 kg over 7 days: daily imbalance = -0.5*7700/7 = -550; implied TDEE = 2000 - (-550) = 2550
  let result = ExpenditureEstimate.compute(
    ~totalKcalLogged=14000.,
    ~daysLogged=7,
    ~weightChangeKg=-0.5,
    ~days=7,
  )
  expect(result.impliedTdeeKcal)->toBe(2550.)
})

test("a weight gain implies a lower TDEE than average intake", () => {
  // +0.35 kg over 7 days: daily imbalance = 0.35*7700/7 = 385; implied TDEE = 2500 - 385 = 2115
  let result = ExpenditureEstimate.compute(
    ~totalKcalLogged=17500.,
    ~daysLogged=7,
    ~weightChangeKg=0.35,
    ~days=7,
  )
  expect(result.avgDailyIntakeKcal)->toBe(2500.)
  expect(result.impliedTdeeKcal)->toBe(2115.)
})
