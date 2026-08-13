// Renders a TargetAdjustment (FR-D-4: explainability). Withheld shows only
// the neutral message — no numbers, nothing to apply. Proposed shows the
// numeric breakdown plus Apply/Dismiss. Apply has no Pro gate yet (FR-D-7) —
// there's no subscription concept in this client to gate against.
let round = f => f->Math.round->Float.toString

@react.component
let make = (~adjustment: TargetAdjustment.t, ~onApply: int => unit, ~onDismiss: unit => unit) =>
  switch adjustment {
  | TargetAdjustment.Withheld(message) =>
    <div className="adjustment-card">
      <p> {React.string(message)} </p>
      <button className="link" onClick={_ => onDismiss()}>
        {React.string("Dismiss")}
      </button>
    </div>
  | Proposed(explanation) =>
    <div className="adjustment-card">
      <h3> {React.string("Weekly target update")} </h3>
      <p>
        {React.string(
          `Based on ${explanation.estimate.avgDailyIntakeKcal->round} kcal/day logged and a ` ++
          `${explanation.estimate.weightChangeKg->round} kg weight change over ` ++
          `${explanation.estimate.days->Int.toString} days, your actual expenditure looks ` ++
          `closer to ${explanation.estimate.impliedTdeeKcal->round} kcal/day.`,
        )}
      </p>
      <p>
        {React.string(
          `Target: ${explanation.previousGoalKcal->Int.toString} kcal → ${explanation.proposedGoalKcal->Int.toString} kcal/day.`,
        )}
      </p>
      <div className="form-actions">
        <button className="primary" onClick={_ => onApply(explanation.proposedGoalKcal)}>
          {React.string("Apply")}
        </button>
        <button className="link" onClick={_ => onDismiss()}>
          {React.string("Dismiss")}
        </button>
      </div>
    </div>
  }
