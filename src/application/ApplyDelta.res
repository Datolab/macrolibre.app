// Use case: apply a dataset delta (FR-C-2) only if the result is provably what
// the producer signed, and otherwise leave the store untouched (FR-C-5).
//
// Deliberately verify-then-commit rather than commit-then-roll-back: the
// prospective dataset is assembled in memory, its digest compared against the
// delta's checksum, and only then written. A partially-applied delta is exactly
// the corruption rollback exists to undo, so it is better never to create one.
//
// This holds the dataset in memory during a sync. That is fine at the bundle's
// 25 MB budget (NFR-3) and is the same cost already paid during first-run
// ingestion; if the dataset outgrows that, this is the place to switch to an
// IndexedDB transaction that aborts on mismatch.

type outcome =
  | Applied({version: string, recordCount: int})
  | Rejected(string)

let run = async (~repository: FoodRepository.t, ~delta: DatasetDelta.t): outcome => {
  let existing = await repository.all()

  // A full snapshot replaces everything; a delta layers onto what's there.
  let base = DatasetDelta.isFullSnapshot(delta) ? [] : existing
  let removed = Set.fromArray(delta.removed)
  let changedIds = Set.fromArray(delta.changed->Array.map(food => food.Food.id))

  let kept =
    base->Array.filter(food => !Set.has(removed, food.Food.id) && !Set.has(changedIds, food.Food.id))
  let prospective = Array.concat(kept, delta.changed)

  let digest = await DatasetDigest.compute(prospective)
  if digest != delta.checksum {
    Rejected(
      `Dataset digest mismatch after applying ${delta.toVersion}: expected ${delta.checksum}, computed ${digest}. Nothing was written.`,
    )
  } else {
    // Verified — now commit. Deletions first so a record that was removed and
    // re-added in the same delta ends up present.
    let toDelete = existing->Array.filter(food =>
      Set.has(removed, food.Food.id) ||
        (DatasetDelta.isFullSnapshot(delta) && !Set.has(changedIds, food.Food.id))
    )
    let _ = await toDelete->Array.map(food => repository.remove(food.Food.id))->Promise.all
    await repository.upsertMany(delta.changed)
    Applied({version: delta.toVersion, recordCount: Array.length(prospective)})
  }
}
