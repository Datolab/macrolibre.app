open Vitest

// Golden vector produced by `datocal.com`'s signer. The delta signing payload's
// byte encoding is normative in the public contract (macrolibre-api-spec,
// `DatasetDelta.signature`); pinning the exact bytes here means a change to
// either implementation fails loudly instead of silently rejecting every delta.
//
// The fixture is chosen so `checksum` and the changed-records digest differ
// (Rice is unchanged and so absent from `changed`) — otherwise a mix-up between
// those two fields would go undetected.

let deltaJson = `{"from_version":"v2026.08","to_version":"v2026.09","layer":"open","checksum":"900631d5d02a31f71c3a0bd436a25c325951e85932ce7e06c62f14ca0dfccf1f","signature":"6lpatQRKnNoAV7HDCG9aAcO2jFQHraNm+o0QaiFx9p1pKhrS/Tl6eMLtsnGHnKEK0+OiwiDHRGTOI1/eVcFtCw==","public_key":"6kpsY+KcUgq+9VB7Ey7F+ZVHdq6+vnuSQh7qaRRG0iw=","changed":[{"id":"c8e288de-459e-5e50-aaa2-51e46caf77eb","name_en":"Corn","provenance_badge":"open_data","kcal_100g":80.0,"protein_100g":0.0,"carbs_100g":20.0,"fat_100g":0.0}],"removed":["9ed18899-82c3-5836-90bb-605cf6d01605"]}`

let trustedKey = "6kpsY+KcUgq+9VB7Ey7F+ZVHdq6+vnuSQh7qaRRG0iw="

let payloadHex = "6d6163726f6c696272652d64656c74612d7631000000000000000876323032362e3038000000000000000876323032362e303900000000000000046f70656e000000000000004039303036333164356430326133316637316333613062643433366132356333323539353165383539333263653765303663363266313463613064666363663166000000000000004065396238643166663636346364663465363565346332643565303665383334323662396364626531666536323463383134623938646433323239353432643236000000000000000131000000000000002439656431383839392d383263332d353833362d393062622d363035636636643031363035"

let decoded = () =>
  switch DeltaDecoder.decode(JSON.parseExn(deltaJson)) {
  | Ok(delta) => delta
  | Error(_) => Exn.raiseError("fixture must decode")
  }

testAsync("builds the signing payload the producer signed", async () => {
  let bytes = await DeltaSignature.signingPayloadHex(decoded())
  expect(bytes)->toBe(payloadHex)
})

testAsync("accepts a genuine signature from the trusted key", async () => {
  let verified = await DeltaSignature.verify(~delta=decoded(), ~trustedPublicKey=trustedKey)
  expect(verified)->toBe(true)
})

testAsync("rejects a delta whose contents were altered after signing", async () => {
  // The attack the signature exists to stop: the payload covers a digest of the
  // changed records, so editing one invalidates it even though the JSON stays
  // well-formed and self-consistent.
  let tampered = {...decoded(), toVersion: "v2027.01"}
  let verified = await DeltaSignature.verify(~delta=tampered, ~trustedPublicKey=trustedKey)
  expect(verified)->toBe(false)
})

testAsync("rejects a signature that verifies under a different key", async () => {
  // A valid signature from a key we do not trust must not be accepted, or the
  // whole trust anchor is meaningless.
  let otherKey = "A6EHv/POEL4dcN0Y50vAmWfk1jCbpQ1fHdyGZBJVMbg="
  let verified = await DeltaSignature.verify(~delta=decoded(), ~trustedPublicKey=otherKey)
  expect(verified)->toBe(false)
})

testAsync("rejects a malformed signature rather than throwing", async () => {
  let broken = {...decoded(), signature: "not-base64!!"}
  let verified = await DeltaSignature.verify(~delta=broken, ~trustedPublicKey=trustedKey)
  expect(verified)->toBe(false)
})
