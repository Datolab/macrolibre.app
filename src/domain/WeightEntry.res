// A single day's weigh-in (FR-D-2). Keyed by day, not id — one weigh-in per
// day is the natural model; a repeat entry for the same day is an upsert.
type t = {
  day: string,
  kg: float,
  loggedAt: float,
}

let build = (~kg: float, ~day: string, ~loggedAt: float): option<t> =>
  Float.isFinite(kg) && kg > 0. ? Some({day, kg, loggedAt}) : None
