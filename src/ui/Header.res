// Fixed top app bar: the wordmark and a hamburger that opens the bottom drawer.
@react.component
let make = (~onMenu: unit => unit) =>
  <header className="app-header">
    <h1> {React.string("MacroLibre")} </h1>
    <button className="hamburger" ariaLabel="Open menu" onClick={_ => onMenu()}>
      {React.string("\u{2630}")}
    </button>
  </header>
