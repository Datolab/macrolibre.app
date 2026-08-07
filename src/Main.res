// App entry: mount the React shell. Runs on import from index.html.
switch ReactDOM.querySelector("#root") {
| Some(root) => ReactDOM.Client.createRoot(root)->ReactDOM.Client.Root.render(<App />)
| None => Console.error("root element #root not found")
}
