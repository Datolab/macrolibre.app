// Ed25519 verification of a signed delta (FR-C-3). A delta is applied
// unattended, so authenticity has to be checked before anything is written: the
// dataset digest alone only proves the payload is internally consistent, which
// an attacker who authored the payload can trivially arrange.
//
// The signing payload's byte encoding is NORMATIVE in the public contract
// (macrolibre-api-spec, `DatasetDelta.signature`) and must match `datocal.com`'s
// producer exactly; a golden vector pins it in both repos.
//
// The trusted key is passed in rather than read from the delta. The payload's
// own `public_key` field is deliberately ignored here — trusting the key a
// document supplies about itself would make the signature decorative. Where the
// trusted key comes from (pinned at build time, rotated, fetched over a
// separate trust path) is the open key-management decision in datocal.com's
// ROADMAP; this module only requires that the caller has one.

@val @scope(("globalThis", "crypto", "subtle"))
external importKey: (string, CanonicalBytes.t, {"name": string}, bool, array<string>) => promise<'key> =
  "importKey"
@val @scope(("globalThis", "crypto", "subtle"))
external verifySignature: (string, 'key, CanonicalBytes.t, CanonicalBytes.t) => promise<bool> =
  "verify"
@val external atob: string => string = "atob"

let domainTag = "macrolibre-delta-v1"
let algorithm = "Ed25519"

let base64ToBytes = (encoded: string): CanonicalBytes.t => {
  let binary = atob(encoded)
  let bytes = CanonicalBytes.make(String.length(binary))
  for i in 0 to String.length(binary) - 1 {
    CanonicalBytes.set(bytes, i, binary->String.charCodeAt(i)->Float.toInt)
  }
  bytes
}

/// The exact bytes the producer signed for this delta.
///
/// A full snapshot's absent `from_version` is encoded as an empty field, not
/// omitted, so a snapshot and a delta from an empty version can't collide.
let signingPayload = async (delta: DatasetDelta.t): array<int> => {
  let out = []
  CanonicalBytes.pushRaw(out, CanonicalBytes.utf8(domainTag))
  CanonicalBytes.pushField(out, delta.fromVersion->Option.getOr(""))
  CanonicalBytes.pushField(out, delta.toVersion)
  CanonicalBytes.pushField(out, delta.layer)
  CanonicalBytes.pushField(out, delta.checksum)
  // A digest of the changed records themselves, so a tampered record is caught
  // before it is applied rather than by the post-apply checksum comparison.
  let changedDigest = await DatasetDigest.compute(delta.changed)
  CanonicalBytes.pushField(out, changedDigest)
  CanonicalBytes.pushField(out, Array.length(delta.removed)->Int.toString)
  delta.removed->Array.forEach(id => CanonicalBytes.pushField(out, id))
  out
}

/// Hex rendering of `signingPayload`, for pinning the encoding in tests.
let signingPayloadHex = async (delta: DatasetDelta.t): string => {
  let payload = await signingPayload(delta)
  CanonicalBytes.toHex(CanonicalBytes.toBytes(payload))
}

/// True only if `delta` carries a valid Ed25519 signature from `trustedPublicKey`
/// (base64, 32 bytes). Any malformed input verifies as false rather than
/// throwing — a corrupt delta and a forged one warrant the same response.
let verify = async (~delta: DatasetDelta.t, ~trustedPublicKey: string): bool =>
  try {
    let payload = await signingPayload(delta)
    let key = await importKey(
      "raw",
      base64ToBytes(trustedPublicKey),
      {"name": algorithm},
      false,
      ["verify"],
    )
    await verifySignature(
      algorithm,
      key,
      base64ToBytes(delta.signature),
      CanonicalBytes.toBytes(payload),
    )
  } catch {
  | _ => false
  }
