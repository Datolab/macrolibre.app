open Vitest

// 180 cm / 80 kg: BMR = 10*80 + 6.25*180 - 228 = 1697; TDEE = 1697*1.4 = 2375.8.
test("recommends maintenance calories from height, weight, goal", () => {
  expect(CalorieGoal.recommend(~heightCm=180., ~weightKg=80., ~goal=Goal.Maintain))->toBe(2376)
})

test("subtracts for weight loss and adds for gain", () => {
  expect(CalorieGoal.recommend(~heightCm=180., ~weightKg=80., ~goal=Goal.Lose))->toBe(1876)
  expect(CalorieGoal.recommend(~heightCm=180., ~weightKg=80., ~goal=Goal.Gain))->toBe(2776)
})
