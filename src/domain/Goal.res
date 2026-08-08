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
