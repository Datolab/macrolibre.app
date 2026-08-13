// Inline form for FR-A-5: log raw kcal/P/C/F directly to today, no database
// entry created. An empty description falls back to a generic label — see
// RawLogEntry for the rule. Mirrors CustomFoodForm's shape.
@val @scope("crypto") external randomUUID: unit => string = "randomUUID"
@val @scope("Date") external now: unit => float = "now"

@react.component
let make = (~day: string, ~onSave: LogEntry.t => unit, ~onCancel: unit => unit) => {
  let (name, setName) = React.useState(() => "")
  let (kcal, setKcal) = React.useState(() => "")
  let (protein, setProtein) = React.useState(() => "")
  let (carbs, setCarbs) = React.useState(() => "")
  let (fat, setFat) = React.useState(() => "")

  let num = s => s->String.trim == "" ? 0. : Float.fromString(s)->Option.getOr(-1.)
  let onInput = setter => e => setter(_ => (e->ReactEvent.Form.target)["value"])

  let submit = () =>
    switch RawLogEntry.build(
      ~id=randomUUID(),
      ~name,
      ~kcal=num(kcal),
      ~protein=num(protein),
      ~carbs=num(carbs),
      ~fat=num(fat),
      ~day,
      ~loggedAt=now(),
    ) {
    | Some(entry) => onSave(entry)
    | None => ()
    }

  let field = (label, value, setter) =>
    <label>
      {React.string(label)}
      <input type_="number" value={value} onChange={onInput(setter)} />
    </label>

  <div className="custom-form">
    <h2> {React.string("Quick-add macros")} </h2>
    <label>
      {React.string("Description (optional)")}
      <input value={name} onChange={onInput(setName)} />
    </label>
    <div className="macro-grid">
      {field("kcal", kcal, setKcal)}
      {field("Protein (g)", protein, setProtein)}
      {field("Carbs (g)", carbs, setCarbs)}
      {field("Fat (g)", fat, setFat)}
    </div>
    <div className="form-actions">
      <button className="primary" onClick={_ => submit()}> {React.string("Add to today")} </button>
      <button className="link" onClick={_ => onCancel()}> {React.string("Cancel")} </button>
    </div>
  </div>
}
