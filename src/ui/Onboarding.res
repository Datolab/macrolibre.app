// First-run onboarding: height, weight, goal -> a recommended daily calorie
// goal. Everything stays local. Renders inside the app shell.
@react.component
let make = (~onComplete: Profile.t => unit) => {
  let (height, setHeight) = React.useState(() => "170")
  let (weight, setWeight) = React.useState(() => "70")
  let (goal, setGoal) = React.useState(() => Goal.Maintain)

  let submit = () =>
    switch (Float.fromString(height), Float.fromString(weight)) {
    | (Some(h), Some(w)) if h > 0. && w > 0. =>
      onComplete({
        Profile.heightCm: h,
        weightKg: w,
        goal,
        kcalGoal: CalorieGoal.recommend(~heightCm=h, ~weightKg=w, ~goal),
      })
    | _ => ()
    }

  <main className="onboarding">
    <h2> {React.string("Welcome to MacroLibre")} </h2>
    <p>
      {React.string(
        "A couple of details to estimate your daily calorie goal. Everything stays on your device — no account needed.",
      )}
    </p>
    <label>
      {React.string("Height (cm)")}
      <input
        type_="number"
        value={height}
        onChange={e => setHeight(_ => (e->ReactEvent.Form.target)["value"])}
      />
    </label>
    <label>
      {React.string("Weight (kg)")}
      <input
        type_="number"
        value={weight}
        onChange={e => setWeight(_ => (e->ReactEvent.Form.target)["value"])}
      />
    </label>
    <label>
      {React.string("Goal")}
      <select
        value={Goal.toString(goal)}
        onChange={e =>
          setGoal(_ =>
            Goal.fromString((e->ReactEvent.Form.target)["value"])->Option.getOr(Goal.Maintain)
          )}>
        <option value="lose"> {React.string("Lose weight")} </option>
        <option value="maintain"> {React.string("Maintain")} </option>
        <option value="gain"> {React.string("Gain weight")} </option>
      </select>
    </label>
    <button className="primary" onClick={_ => submit()}> {React.string("Get started")} </button>
  </main>
}
