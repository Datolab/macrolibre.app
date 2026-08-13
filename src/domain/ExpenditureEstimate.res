// Back-calculates actual daily expenditure from a period's logged intake vs.
// trend-weight change (FR-D-3), the classic energy-balance method: whatever
// intake didn't show up as bodyweight change must have been burned.
// kcalPerKgBodyweight is the Wishnofsky-derived ~3500 kcal/lb figure, a
// long-standing approximation (it mixes fat/lean/water change, not pure fat)
// — named and isolated here so it's easy to find and re-tune.
let kcalPerKgBodyweight = 7700.

type t = {
  impliedTdeeKcal: float,
  avgDailyIntakeKcal: float,
  weightChangeKg: float,
  days: int,
}

let compute = (~totalKcalLogged: float, ~daysLogged: int, ~weightChangeKg: float, ~days: int): t => {
  let avgDailyIntakeKcal = totalKcalLogged /. daysLogged->Int.toFloat
  let dailyImbalanceKcal = weightChangeKg *. kcalPerKgBodyweight /. days->Int.toFloat
  {
    impliedTdeeKcal: avgDailyIntakeKcal -. dailyImbalanceKcal,
    avgDailyIntakeKcal,
    weightChangeKg,
    days,
  }
}
