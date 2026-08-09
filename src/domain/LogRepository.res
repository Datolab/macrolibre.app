// Port (ADR-0002): persistence for the food log. Infrastructure (IndexedDB)
// provides a value of this type.
type t = {
  add: LogEntry.t => promise<unit>,
  listByDay: string => promise<array<LogEntry.t>>,
  remove: string => promise<unit>,
  // Most-recently-logged distinct foods (by name), newest first, for quick-add.
  recent: int => promise<array<LogEntry.t>>,
}
