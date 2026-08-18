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

type uint8Array
type arrayBuffer

@new external makeBytes: int => uint8Array = "Uint8Array"
@new external bytesFromBuffer: arrayBuffer => uint8Array = "Uint8Array"
@new external textEncoder: unit => 'a = "TextEncoder"
@send external encode: ('a, string) => uint8Array = "encode"
@get external byteLength: uint8Array => int = "length"
@get_index external byteAt: (uint8Array, int) => int = ""
@set_index external setByte: (uint8Array, int, int) => unit = ""
@send external setAt: (uint8Array, uint8Array, int) => unit = "set"
@val @scope(("globalThis", "crypto", "subtle"))
external digestBuffer: (string, uint8Array) => promise<arrayBuffer> = "digest"

// Exactly the tag the producer prefixes, so a digest can't be confused with one
// over some other structure.
let domainTag = "macrolibre-dataset-v1"
let nutrientDecimals = 4

let encoder = textEncoder()
let utf8 = (s: string): uint8Array => encoder->encode(s)

// Big-endian u64 length prefix. Byte lengths here are far below 2^32, so the
// high four bytes are always zero — written out anyway to match the producer.
let lengthPrefix = (length: int): array<int> => [
  0,
  0,
  0,
  0,
  land(lsr(length, 24), 255),
  land(lsr(length, 16), 255),
  land(lsr(length, 8), 255),
  land(length, 255),
]

let pushBytes = (out: array<int>, bytes: uint8Array) => {
  let count = byteLength(bytes)
  for i in 0 to count - 1 {
    out->Array.push(byteAt(bytes, i))
  }
}

// A length-prefixed string field.
let pushField = (out: array<int>, value: string) => {
  let bytes = utf8(value)
  lengthPrefix(byteLength(bytes))->Array.forEach(b => out->Array.push(b))
  pushBytes(out, bytes)
}

// An optional field: a bare presence marker byte, then the value if present.
// The marker is deliberately not length-prefixed.
let pushOptional = (out: array<int>, value: option<string>) =>
  switch value {
  | None => out->Array.push(0)
  | Some(v) => {
      out->Array.push(1)
      pushField(out, v)
    }
  }

// `toFixed` matches Rust's `{:.4}` for non-negative values. Negative zero is
// normalised because Rust would render it "-0.0000" and JS renders "0.0000".
let formatNutrient = (value: float): string => {
  let normalized = value == 0. ? 0. : value
  normalized->Float.toFixed(~digits=nutrientDecimals)
}

// One record's canonical bytes.
let encodeFood = (food: Food.t): array<int> => {
  let out = []
  pushField(out, food.id)
  pushField(out, food.nameEn)
  pushOptional(out, food.nameEs)
  pushOptional(out, food.region)
  [food.kcal100g, food.protein100g, food.carbs100g, food.fat100g]->Array.forEach(value =>
    pushField(out, formatNutrient(value))
  )
  out
}

// Lexicographic byte-order comparison, which is what makes the digest
// order-independent once records are sorted by their encodings.
let compareBytes = (a: array<int>, b: array<int>): float => {
  let (lenA, lenB) = (Array.length(a), Array.length(b))
  let shorter = lenA < lenB ? lenA : lenB
  let index = ref(0)
  let result = ref(0)
  while result.contents == 0 && index.contents < shorter {
    let x = a->Array.getUnsafe(index.contents)
    let y = b->Array.getUnsafe(index.contents)
    if x != y {
      result := if x < y {
        -1
      } else {
        1
      }
    }
    index := index.contents + 1
  }
  if result.contents != 0 {
    result.contents->Int.toFloat
  } else {
    (lenA - lenB)->Int.toFloat
  }
}

let toHex = (bytes: uint8Array): string => {
  let out = []
  for i in 0 to byteLength(bytes) - 1 {
    let hex = byteAt(bytes, i)->Int.toString(~radix=16)
    out->Array.push(String.length(hex) == 1 ? "0" ++ hex : hex)
  }
  out->Array.join("")
}

/// Lowercase-hex SHA-256 dataset digest of `foods`, independent of their order.
let compute = async (foods: array<Food.t>): string => {
  // Sorting the encoded records (each of which begins with the id) is what
  // makes the result order-independent.
  let sorted = foods->Array.map(encodeFood)->Array.toSorted(compareBytes)

  let tag = utf8(domainTag)
  let tagLength = byteLength(tag)
  let total = sorted->Array.reduce(0, (sum, record) => sum + Array.length(record))

  let message = makeBytes(tagLength + total)
  message->setAt(tag, 0)
  let cursor = ref(tagLength)
  sorted->Array.forEach(record =>
    record->Array.forEach(byte => {
      setByte(message, cursor.contents, byte)
      cursor := cursor.contents + 1
    })
  )

  let hash = await digestBuffer("SHA-256", message)
  toHex(bytesFromBuffer(hash))
}
