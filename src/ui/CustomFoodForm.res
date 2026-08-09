// Inline form to create a custom food (name + per-100g macros). Builds a
// validated Food.t via CustomFood and hands it back; empty macro fields count
// as 0, an unparseable one is rejected.
@val @scope("crypto") external randomUUID: unit => string = "randomUUID"

@react.component
let make = (~onSave: Food.t => unit, ~onCancel: unit => unit) => {
  let (name, setName) = React.useState(() => "")
  let (kcal, setKcal) = React.useState(() => "")
  let (protein, setProtein) = React.useState(() => "")
  let (carbs, setCarbs) = React.useState(() => "")
  let (fat, setFat) = React.useState(() => "")

  let num = s => s->String.trim == "" ? 0. : Float.fromString(s)->Option.getOr(-1.)
  let onInput = setter => e => setter(_ => (e->ReactEvent.Form.target)["value"])

  let submit = () =>
    switch CustomFood.build(
      ~id=randomUUID(),
      ~name,
      ~kcal=num(kcal),
      ~protein=num(protein),
      ~carbs=num(carbs),
      ~fat=num(fat),
    ) {
    | Some(food) => onSave(food)
    | None => ()
    }

  let field = (label, value, setter) =>
    <label>
      {React.string(label)}
      <input type_="number" value={value} onChange={onInput(setter)} />
    </label>

  <div className="custom-form">
    <h2> {React.string("New custom food")} </h2>
    <label>
      {React.string("Name")}
      <input value={name} onChange={onInput(setName)} />
    </label>
    <div className="macro-grid">
      {field("kcal / 100 g", kcal, setKcal)}
      {field("Protein (g)", protein, setProtein)}
      {field("Carbs (g)", carbs, setCarbs)}
      {field("Fat (g)", fat, setFat)}
    </div>
    <div className="form-actions">
      <button className="primary" onClick={_ => submit()}> {React.string("Save")} </button>
      <button className="link" onClick={_ => onCancel()}> {React.string("Cancel")} </button>
    </div>
  </div>
}
