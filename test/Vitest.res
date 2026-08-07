// Minimal ReScript bindings to Vitest's global `test`/`expect` (globals: true).
type expectation<'a>

@val external test: (string, unit => unit) => unit = "test"
@val external expect: 'a => expectation<'a> = "expect"
@send external toBe: (expectation<'a>, 'a) => unit = "toBe"
@send external toEqual: (expectation<'a>, 'a) => unit = "toEqual"
