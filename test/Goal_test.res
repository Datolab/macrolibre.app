open Vitest

test("gives a daily kcal offset per goal", () => {
  expect(Goal.kcalOffset(Goal.Lose))->toBe(-500.)
  expect(Goal.kcalOffset(Goal.Maintain))->toBe(0.)
  expect(Goal.kcalOffset(Goal.Gain))->toBe(400.)
})
