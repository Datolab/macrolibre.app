// Port (ADR-0002): persistence for saved meal templates. Infrastructure
// (IndexedDB) provides a value of this type.
type t = {
  add: MealTemplate.t => promise<unit>,
  listAll: unit => promise<array<MealTemplate.t>>,
  remove: string => promise<unit>,
}
