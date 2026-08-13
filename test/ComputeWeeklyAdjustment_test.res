open Vitest

let last7Days = [
  "2026-08-07",
  "2026-08-08",
  "2026-08-09",
  "2026-08-10",
  "2026-08-11",
  "2026-08-12",
  "2026-08-13",
]

let logEntry = (day, kcal): LogEntry.t => {
  id: day,
  foodName: "food",
  grams: 100.,
  macros: {Macros.kcal, protein: 0., carbs: 0., fat: 0.},
  day,
  loggedAt: 0.,
}

testAsync("proposes a new target from the week's weights and logs", async () => {
  // Weight logged (same 80 kg) on the first 4 days -> stable trend, meets the
  // 4-day confidence threshold exactly. Logs on 6 of 7 days, 2000 kcal each.
  let weights = ref([
    {WeightEntry.day: "2026-08-07", kg: 80., loggedAt: 0.},
    {WeightEntry.day: "2026-08-08", kg: 80., loggedAt: 0.},
    {WeightEntry.day: "2026-08-09", kg: 80., loggedAt: 0.},
    {WeightEntry.day: "2026-08-10", kg: 80., loggedAt: 0.},
  ])
  let weightRepo: WeightRepository.t = {
    record: async entry => weights := Array.concat(weights.contents, [entry]),
    listAll: async () => weights.contents,
  }
  let logsByDay = Dict.make()
  [
    "2026-08-07",
    "2026-08-08",
    "2026-08-09",
    "2026-08-10",
    "2026-08-11",
    "2026-08-12",
  ]->Array.forEach(day => logsByDay->Dict.set(day, [logEntry(day, 2000.)]))
  let logRepo: LogRepository.t = {
    add: async _ => (),
    listByDay: async day => logsByDay->Dict.get(day)->Option.getOr([]),
    remove: async _ => (),
    recent: async _ => [],
  }

  let result = await ComputeWeeklyAdjustment.run(
    ~weightRepo,
    ~logRepo,
    ~last7Days,
    ~previousGoalKcal=2200,
    ~goal=Goal.Maintain,
  )

  switch result {
  | TargetAdjustment.Proposed(explanation) => {
      expect(explanation.estimate.avgDailyIntakeKcal)->toBe(2000.)
      expect(explanation.estimate.weightChangeKg)->toBe(0.)
      expect(explanation.proposedGoalKcal)->toBe(2000)
    }
  | Withheld(msg) => Console.log(msg)->ignore; expect(false)->toBe(true)
  }
})

testAsync("withholds when the week has too little data", async () => {
  let weightRepo: WeightRepository.t = {
    record: async _ => (),
    listAll: async () => [],
  }
  let logRepo: LogRepository.t = {
    add: async _ => (),
    listByDay: async _ => [],
    remove: async _ => (),
    recent: async _ => [],
  }

  let result = await ComputeWeeklyAdjustment.run(
    ~weightRepo,
    ~logRepo,
    ~last7Days,
    ~previousGoalKcal=2200,
    ~goal=Goal.Maintain,
  )

  switch result {
  | TargetAdjustment.Withheld(_) => expect(true)->toBe(true)
  | Proposed(_) => expect(false)->toBe(true)
  }
})
