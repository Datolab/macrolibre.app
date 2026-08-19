// The dataset content digest (FR-C-2/C-3). Recomputed here after applying a
// delta so the client can prove it ended up with exactly the records the
// producer signed — a delta leaves us holding records, not bundle bytes, so the
// release artifact's checksum is no help at that point.
//
// The byte encoding is NORMATIVE in the public contract (macrolibre-api-spec,
// `DatasetDelta.checksum`) and must match `datocal.com`'s Rust producer exactly.
// Golden vectors shared with that repo pin both implementations — see
// test/DatasetDigest_test.res. Do not "tidy" anything here without changing the
// spec and both test suites together.
//
// Lives in domain/ despite using Web Crypto: the encoding is a domain rule, and
// SubtleCrypto is a platform primitive (like Math), not an adapter to a service.

@val @scope(("globalThis", "crypto", "subtle"))
external digest: (string, CanonicalBytes.t) => promise<'buffer> = "digest"

let domainTag = "macrolibre-dataset-v1"
let nutrientDecimals = 4

// `toFixed` rounds ties half up, which is what the contract specifies (many
// languages, Rust included, round half to even by default and would disagree on
// roughly 1% of real nutrient values). Negative zero is normalised because it
// would otherwise render "-0.0000" on the producer side.
let formatNutrient = (value: float): string => {
  let normalized = value == 0. ? 0. : value
  normalized->Float.toFixed(~digits=nutrientDecimals)
}

// One record's canonical bytes.
let encodeFood = (food: Food.t): array<int> => {
  let out = []
  CanonicalBytes.pushField(out, food.id)
  CanonicalBytes.pushField(out, food.nameEn)
  CanonicalBytes.pushOptional(out, food.nameEs)
  CanonicalBytes.pushOptional(out, food.region)
  [food.kcal100g, food.protein100g, food.carbs100g, food.fat100g]->Array.forEach(value =>
    CanonicalBytes.pushField(out, formatNutrient(value))
  )
  out
}

/// Lowercase-hex SHA-256 dataset digest of `foods`, independent of their order.
let compute = async (foods: array<Food.t>): string => {
  // Sorting the encoded records (each of which begins with the id) is what makes
  // the result order-independent.
  let sorted = foods->Array.map(encodeFood)->Array.toSorted(CanonicalBytes.compare)

  let message = []
  CanonicalBytes.pushRaw(message, CanonicalBytes.utf8(domainTag))
  sorted->Array.forEach(record => record->Array.forEach(byte => message->Array.push(byte)))

  let hash = await digest("SHA-256", CanonicalBytes.toBytes(message))
  CanonicalBytes.toHex(CanonicalBytes.fromBuffer(hash))
}
