// The public contract's canonical byte encoding, shared by everything the
// producer signs or digests (macrolibre-api-spec, Epic C): every string field is
// preceded by its UTF-8 byte length as a big-endian u64. Both the dataset digest
// and the delta signing payload are built from these, so they live in one place
// — an inconsistency between them would only ever show up as an unexplained
// verification failure.

type t

@new external make: int => t = "Uint8Array"
@new external fromBuffer: 'buffer => t = "Uint8Array"
@new external textEncoder: unit => 'a = "TextEncoder"
@send external encodeString: ('a, string) => t = "encode"
@get external length: t => int = "length"
@get_index external get: (t, int) => int = ""
@set_index external set: (t, int, int) => unit = ""

let encoder = textEncoder()
let utf8 = (s: string): t => encoder->encodeString(s)

// Byte lengths here are far below 2^32, so the high four bytes are always zero;
// written out anyway because the encoding specifies a u64.
let lengthPrefix = (byteCount: int): array<int> => [
  0,
  0,
  0,
  0,
  land(lsr(byteCount, 24), 255),
  land(lsr(byteCount, 16), 255),
  land(lsr(byteCount, 8), 255),
  land(byteCount, 255),
]

let pushRaw = (out: array<int>, bytes: t) => {
  let count = length(bytes)
  for i in 0 to count - 1 {
    out->Array.push(get(bytes, i))
  }
}

/// Appends a length-prefixed string field.
let pushField = (out: array<int>, value: string) => {
  let bytes = utf8(value)
  lengthPrefix(length(bytes))->Array.forEach(b => out->Array.push(b))
  pushRaw(out, bytes)
}

/// Appends an optional field: a bare presence marker byte, then the value if
/// present. The marker is deliberately not length-prefixed.
let pushOptional = (out: array<int>, value: option<string>) =>
  switch value {
  | None => out->Array.push(0)
  | Some(v) => {
      out->Array.push(1)
      pushField(out, v)
    }
  }

let toBytes = (values: array<int>): t => {
  let bytes = make(Array.length(values))
  values->Array.forEachWithIndex((value, i) => set(bytes, i, value))
  bytes
}

/// Lexicographic byte-order comparison, shorter-is-smaller on a common prefix.
let compare = (a: array<int>, b: array<int>): float => {
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

let toHex = (bytes: t): string => {
  let out = []
  for i in 0 to length(bytes) - 1 {
    let hex = get(bytes, i)->Int.toString(~radix=16)
    out->Array.push(String.length(hex) == 1 ? "0" ++ hex : hex)
  }
  out->Array.join("")
}
