// The user's profile + derived daily calorie goal. Stored locally (no account).
type t = {
  heightCm: float,
  weightKg: float,
  goal: Goal.t,
  kcalGoal: int,
}
