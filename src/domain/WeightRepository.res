// Port (ADR-0002): persistence for daily weigh-ins. Infrastructure (IndexedDB)
// provides a value of this type.
type t = {
  // Upserts by day — a second weigh-in on the same day replaces the first.
  record: WeightEntry.t => promise<unit>,
  // All weigh-ins ever recorded, ordered by day ascending (small, local data;
  // the trend-weight fold needs the whole history, not a windowed query).
  listAll: unit => promise<array<WeightEntry.t>>,
}
