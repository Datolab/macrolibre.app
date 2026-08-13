open Vitest

test("withholds with a weight-specific message when weigh-ins are too thin", () => {
  switch TargetAdjustment.propose(
    ~weightDaysLogged=2,
    ~intakeDaysLogged=6,
    ~totalKcalLogged=12000.,
    ~weightChangeKg=-0.5,
    ~days=7,
    ~previousGoalKcal=2200,
    ~goal=Goal.Lose,
  ) {
  | TargetAdjustment.Withheld(msg) => expect(msg->String.includes("weight"))->toBe(true)
  | Proposed(_) => expect(false)->toBe(true)
  }
})

test("withholds with a logging-specific message when meal logging is too thin", () => {
  switch TargetAdjustment.propose(
    ~weightDaysLogged=6,
    ~intakeDaysLogged=1,
    ~totalKcalLogged=2000.,
    ~weightChangeKg=-0.5,
    ~days=7,
    ~previousGoalKcal=2200,
    ~goal=Goal.Lose,
  ) {
  | TargetAdjustment.Withheld(msg) => expect(msg->String.includes("meal"))->toBe(true)
  | Proposed(_) => expect(false)->toBe(true)
  }
})

test("proposes a new target from the implied TDEE plus the goal's offset", () => {
  // avg intake = 12000/6 = 2000; imbalance = -0.5*7700/7 = -550; implied TDEE = 2550
  // proposed = 2550 + Goal.kcalOffset(Lose) = 2550 - 500 = 2050
  switch TargetAdjustment.propose(
    ~weightDaysLogged=5,
    ~intakeDaysLogged=6,
    ~totalKcalLogged=12000.,
    ~weightChangeKg=-0.5,
    ~days=7,
    ~previousGoalKcal=2200,
    ~goal=Goal.Lose,
  ) {
  | TargetAdjustment.Proposed(explanation) => {
      expect(explanation.previousGoalKcal)->toBe(2200)
      expect(explanation.proposedGoalKcal)->toBe(2050)
      expect(explanation.estimate.impliedTdeeKcal)->toBe(2550.)
    }
  | Withheld(_) => expect(false)->toBe(true)
  }
})
