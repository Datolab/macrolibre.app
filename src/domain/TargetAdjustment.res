// The weekly target proposal (FR-D-3/4/5/6): either a real numeric proposal
// with its full breakdown, or a withheld week with a kind, specific reason —
// modeled as a sum type so a caller must handle both, never a null/omitted
// number standing in for "not enough data".
type explanation = {
  estimate: ExpenditureEstimate.t,
  previousGoalKcal: int,
  proposedGoalKcal: int,
}

type t =
  | Proposed(explanation)
  | Withheld(string)

// Of the 7-day window, how many days need real data on each side before a
// proposal is trustworthy. Not SRS-mandated; a reasonable, tunable default.
let minDaysWithData = 4

let propose = (
  ~weightDaysLogged: int,
  ~intakeDaysLogged: int,
  ~totalKcalLogged: float,
  ~weightChangeKg: float,
  ~days: int,
  ~previousGoalKcal: int,
  ~goal: Goal.t,
): t =>
  if weightDaysLogged < minDaysWithData {
    Withheld("Log your weight a few more days this week and we'll have enough to update your target.")
  } else if intakeDaysLogged < minDaysWithData {
    Withheld("Log your meals a few more days this week and we'll have enough to update your target.")
  } else {
    let estimate = ExpenditureEstimate.compute(
      ~totalKcalLogged,
      ~daysLogged=intakeDaysLogged,
      ~weightChangeKg,
      ~days,
    )
    let proposedGoalKcal = (estimate.impliedTdeeKcal +. Goal.kcalOffset(goal))->Math.round->Int.fromFloat
    Proposed({estimate, previousGoalKcal, proposedGoalKcal})
  }
