// A rough initial daily-calorie recommendation from height, weight, and goal.
// Simplified Mifflin–St Jeor (neutral age/sex) times a light activity factor,
// then a goal offset. This is a *starting* estimate; the M4 adaptation engine
// (FR-D) refines it from real weight-trend data.
let recommend = (~heightCm: float, ~weightKg: float, ~goal: Goal.t): int => {
  // Mifflin–St Jeor with age 30 and a sex-neutral constant (avg of +5 / -161).
  let bmr = 10. *. weightKg +. 6.25 *. heightCm -. 228.
  let tdee = bmr *. 1.4 // lightly active
  let adjusted = tdee +. Goal.kcalOffset(goal)
  adjusted->Math.round->Int.fromFloat
}
