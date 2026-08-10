// A saved set of foods+quantities a user logs together in one action (FR-A:
// "log several foods at once"). Items denormalize macros at save time, same
// rationale as LogEntry — a template should log what its items said at the
// time it was built, not whatever the food record says today.
type item = {
  foodId: string,
  foodName: string,
  grams: float,
  macros: Macros.t,
}

type t = {
  id: string,
  name: string,
  items: array<item>,
}
