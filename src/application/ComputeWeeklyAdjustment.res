// Use case: compute this week's target proposal (FR-D-3). Orchestrates the
// weight and log ports into TargetAdjustment's inputs — no math of its own.
// `last7Days` (day-ascending, last entry is "today") is supplied by the
// caller rather than computed here, matching how the rest of the app passes
// in day/time values (LogFood's ~day, ~loggedAt) instead of a ClockPort.
let run = async (
  ~weightRepo: WeightRepository.t,
  ~logRepo: LogRepository.t,
  ~last7Days: array<string>,
  ~previousGoalKcal: int,
  ~goal: Goal.t,
): TargetAdjustment.t => {
  let weights = await weightRepo.listAll()
  let sorted = weights->Array.toSorted((a, b) => String.compare(a.day, b.day))
  let trend = TrendWeight.series(sorted)

  // The latest trend point at or before a given day (weigh-ins don't
  // necessarily land exactly on the window's first/last day).
  let trendAsOf = day => {
    let upTo = trend->Array.filter(((d, _)) => d <= day)
    upTo->Array.get(Array.length(upTo) - 1)->Option.map(((_, kg)) => kg)
  }

  let today = last7Days->Array.get(Array.length(last7Days) - 1)->Option.getOr("")
  let weekAgo = last7Days->Array.get(0)->Option.getOr("")
  let weightChangeKg = switch (trendAsOf(today), trendAsOf(weekAgo)) {
  | (Some(end_), Some(start)) => end_ -. start
  | _ => 0.
  }

  let weightDaysLogged =
    sorted->Array.filter(w => last7Days->Array.filter(d => d == w.day)->Array.length > 0)->Array.length

  let logsByDay = await last7Days->Array.map(day => logRepo.listByDay(day))->Promise.all
  let totalKcalLogged = logsByDay->Array.reduce(0., (total, dayEntries) =>
    total +. dayEntries->Array.reduce(0., (sum, e: LogEntry.t) => sum +. e.macros.kcal)
  )
  let intakeDaysLogged = logsByDay->Array.filter(dayEntries => Array.length(dayEntries) > 0)->Array.length

  TargetAdjustment.propose(
    ~weightDaysLogged,
    ~intakeDaysLogged,
    ~totalKcalLogged,
    ~weightChangeKg,
    ~days=Array.length(last7Days),
    ~previousGoalKcal,
    ~goal,
  )
}
