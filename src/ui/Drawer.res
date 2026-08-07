// Bottom drawer (slide-up sheet) opened from the header. Holds app info, the
// OFF/ODbL attribution the client must surface (ADR-0006), and a reset action.

// Clear all local IndexedDB databases and reload — a local-first "start over".
let resetLocalData: unit => unit = %raw(`
  async () => {
    const dbs = (await indexedDB.databases?.()) || [];
    await Promise.all(dbs.map(d => new Promise((res) => {
      const req = indexedDB.deleteDatabase(d.name);
      req.onsuccess = req.onerror = req.onblocked = res;
    })));
    location.reload();
  }
`)

@react.component
let make = (~isOpen: bool, ~onClose: unit => unit) => {
  let cls = base => isOpen ? base ++ " open" : base
  <>
    <div className={cls("backdrop")} onClick={_ => onClose()} />
    <div className={cls("drawer")} role="dialog">
      <div className="grabber" />
      <h3> {React.string("About")} </h3>
      <p>
        {React.string(
          "MacroLibre is a local-first, open-source macro tracker. Everything works offline, with no account. The client is licensed AGPL-3.0.",
        )}
      </p>
      <h3> {React.string("Data & attribution")} </h3>
      <p>
        {React.string(
          "Contains information from Open Food Facts, made available under the Open Database License (ODbL). USDA FoodData Central records are public domain.",
        )}
      </p>
      <button className="primary" onClick={_ => resetLocalData()}>
        {React.string("Reset local data")}
      </button>
    </div>
  </>
}
