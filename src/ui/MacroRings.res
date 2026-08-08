// Apple Watch–style activity rings: three concentric rings for protein, carbs,
// and fat, each filling toward its daily target, with the calorie total in the
// centre. Thick strokes with rounded caps on dim coloured tracks.

let tau = 2. *. Math.Constants.pi

// One ring: a dim full track plus a rounded progress arc starting at 12 o'clock.
let ring = (~radius, ~color, ~track, ~value, ~target) => {
  let circumference = tau *. radius
  let fraction = target > 0. ? Math.min(value /. target, 1.) : 0.
  let dash = `${(circumference *. fraction)->Float.toString} ${circumference->Float.toString}`
  let r = radius->Float.toString
  <>
    <circle cx="60" cy="60" r fill="none" stroke=track strokeWidth="10" />
    <circle
      cx="60"
      cy="60"
      r
      fill="none"
      stroke=color
      strokeWidth="10"
      strokeDasharray=dash
      strokeLinecap="round"
      transform="rotate(-90 60 60)"
    />
  </>
}

@react.component
let make = (~consumed: Macros.t, ~targets: MacroTargets.t, ~calorieGoal: int) => {
  let dot = (color, label, value, target) =>
    <span className="legend-item">
      <span className="dot" style={ReactDOM.Style.make(~background=color, ())} />
      {React.string(
        `${label} ${value->Math.round->Float.toString}/${target->Math.round->Float.toString} g`,
      )}
    </span>

  <div className="rings">
    <svg viewBox="0 0 120 120">
      {ring(
        ~radius=52.,
        ~color="#34d399",
        ~track="rgba(52,211,153,0.2)",
        ~value=consumed.protein,
        ~target=targets.protein,
      )}
      {ring(
        ~radius=40.,
        ~color="#fbbf24",
        ~track="rgba(251,191,36,0.2)",
        ~value=consumed.carbs,
        ~target=targets.carbs,
      )}
      {ring(
        ~radius=28.,
        ~color="#fb7185",
        ~track="rgba(251,113,133,0.2)",
        ~value=consumed.fat,
        ~target=targets.fat,
      )}
      <text x="60" y="57" textAnchor="middle" className="rings-num">
        {React.string(consumed.kcal->Math.round->Float.toString)}
      </text>
      <text x="60" y="73" textAnchor="middle" className="rings-sub">
        {React.string(`/ ${calorieGoal->Int.toString} kcal`)}
      </text>
    </svg>
    <div className="legend">
      {dot("#34d399", "Protein", consumed.protein, targets.protein)}
      {dot("#fbbf24", "Carbs", consumed.carbs, targets.carbs)}
      {dot("#fb7185", "Fat", consumed.fat, targets.fat)}
    </div>
  </div>
}
