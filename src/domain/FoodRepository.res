// Port (ADR-0002): the application's view of stored foods. Infrastructure
// (IndexedDB) provides a value of this type; the application never knows how or
// where foods are persisted.
type t = {
  upsertMany: array<Food.t> => promise<unit>,
  searchByName: string => promise<array<Food.t>>,
  count: unit => promise<int>,
  // Delete one food by id — needed to apply a delta's tombstones (FR-C-2).
  remove: string => promise<unit>,
  // Every stored food. Used to verify a delta's resulting dataset digest before
  // committing it (FR-C-2/C-5); ordinary lookups go through searchByName.
  all: unit => promise<array<Food.t>>,
}
