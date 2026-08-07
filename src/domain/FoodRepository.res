// Port (ADR-0002): the application's view of stored foods. Infrastructure
// (IndexedDB) provides a value of this type; the application never knows how or
// where foods are persisted.
type t = {
  upsertMany: array<Food.t> => promise<unit>,
  searchByName: string => promise<array<Food.t>>,
  count: unit => promise<int>,
}
