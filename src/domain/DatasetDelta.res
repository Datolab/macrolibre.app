// A delta the client applies to move to a newer dataset release (FR-C-2),
// mirroring the public contract's `DatasetDelta`. `fromVersion == None` means
// this is a full snapshot: replace everything rather than apply on top.
type t = {
  fromVersion: option<string>,
  toVersion: string,
  layer: string,
  // Expected dataset digest once applied — see DatasetDigest.
  checksum: string,
  signature: string,
  changed: array<Food.t>,
  removed: array<string>,
}

let isFullSnapshot = (delta: t): bool => delta.fromVersion == None
