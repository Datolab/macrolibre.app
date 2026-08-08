open Vitest

// 2000 kcal at 30/40/30: protein 0.30*2000/4=150, carbs 0.40*2000/4=200,
// fat 0.30*2000/9=66.67.
test("derives macro targets from the calorie goal", () => {
  let t = MacroTargets.fromCalories(2000)
  expect(t.protein)->toBe(150.)
  expect(t.carbs)->toBe(200.)
  expect(t.fat->Math.round)->toBe(67.)
})
