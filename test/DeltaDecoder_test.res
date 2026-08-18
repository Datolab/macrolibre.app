open Vitest

let json = raw => JSON.parseExn(raw)

let foodJson = `{"id":"8189c6c2-5a0d-5716-b6e9-c720038793da","name_en":"Rice","provenance_badge":"open_data","kcal_100g":130,"protein_100g":2.7,"carbs_100g":28,"fat_100g":0.3}`

test("decodes a delta with changed records and tombstones", () => {
  let raw = `{"from_version":"v2026.08","to_version":"v2026.09","layer":"open","checksum":"abc","signature":"sig","changed":[${foodJson}],"removed":["3a2836c6-6981-5076-820e-5ff2df696832"]}`
  switch DeltaDecoder.decode(json(raw)) {
  | Ok(delta) => {
      expect(delta.fromVersion)->toEqual(Some("v2026.08"))
      expect(delta.toVersion)->toBe("v2026.09")
      expect(delta.checksum)->toBe("abc")
      expect(Array.length(delta.changed))->toBe(1)
      expect(delta.removed)->toEqual(["3a2836c6-6981-5076-820e-5ff2df696832"])
    }
  | Error(_) => expect(false)->toBe(true)
  }
})

test("treats a null from_version as a full snapshot", () => {
  let raw = `{"from_version":null,"to_version":"v2026.09","layer":"open","checksum":"abc","signature":"sig","changed":[],"removed":[]}`
  switch DeltaDecoder.decode(json(raw)) {
  | Ok(delta) => expect(delta.fromVersion)->toEqual(None)
  | Error(_) => expect(false)->toBe(true)
  }
})

test("rejects a delta missing a required field", () => {
  // No checksum: without it the client cannot verify what it applied, so this
  // must not decode into a domain value at all (ADR-0003).
  let raw = `{"from_version":null,"to_version":"v2026.09","layer":"open","signature":"sig","changed":[],"removed":[]}`
  expect(DeltaDecoder.decode(json(raw))->Result.isError)->toBe(true)
})

test("rejects a delta whose changed array holds an undecodable record", () => {
  // A partially-decodable delta is worse than a rejected one: applying it would
  // silently drop records and then fail the digest check for a confusing reason.
  let raw = `{"from_version":null,"to_version":"v2026.09","layer":"open","checksum":"abc","signature":"sig","changed":[{"id":"x"}],"removed":[]}`
  expect(DeltaDecoder.decode(json(raw))->Result.isError)->toBe(true)
})

test("rejects a removed entry that is not a string", () => {
  let raw = `{"from_version":null,"to_version":"v2026.09","layer":"open","checksum":"abc","signature":"sig","changed":[],"removed":[42]}`
  expect(DeltaDecoder.decode(json(raw))->Result.isError)->toBe(true)
})
