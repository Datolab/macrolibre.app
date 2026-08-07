// App entry: mount the React shell. Runs on import from index.html.

// Bundle the wordmark font (self-hosted, offline-safe — Vite inlines the woff2).
%%raw(`import "@fontsource/fredoka/600.css"`)
switch ReactDOM.querySelector("#root") {
| Some(root) => ReactDOM.Client.createRoot(root)->ReactDOM.Client.Root.render(<App />)
| None => Console.error("root element #root not found")
}
