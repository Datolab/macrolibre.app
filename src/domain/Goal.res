// The user's weight goal (SRS USER.goal_type).
type t =
  | Lose
  | Maintain
  | Gain

let toString = g =>
  switch g {
  | Lose => "lose"
  | Maintain => "maintain"
  | Gain => "gain"
  }

let fromString = s =>
  switch s {
  | "lose" => Some(Lose)
  | "maintain" => Some(Maintain)
  | "gain" => Some(Gain)
  | _ => None
  }

let label = g =>
  switch g {
  | Lose => "Lose weight"
  | Maintain => "Maintain"
  | Gain => "Gain weight"
  }

// Daily calorie offset from TDEE for each goal — shared by the onboarding
// estimate (CalorieGoal) and the weekly adaptation engine (TargetAdjustment),
// so both express the same deficit/surplus philosophy from one source.
let kcalOffset = g =>
  switch g {
  | Lose => -500.
  | Maintain => 0.
  | Gain => 400.
  }
