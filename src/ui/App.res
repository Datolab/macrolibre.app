// The PWA shell's root view. A driving adapter (rescript-react) — kept thin;
// domain/application logic lives behind it, not here.
@react.component
let make = () => {
  <main>
    <h1> {React.string("MacroLibre")} </h1>
    <p> {React.string("Local-first macro & nutrition tracker. Works offline, no account.")} </p>
  </main>
}
