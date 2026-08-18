open Vitest

// Golden vectors shared with the producer (`datocal.com`
// tests/digest_vectors.rs). The encoding is normative in the public contract
// (macrolibre-api-spec, `DatasetDelta.checksum`); these same expected values are
// asserted in both repos, so drift on either side fails loudly here rather than
// silently making every delta unverifiable on clients.

let food = (~id, ~nameEn, ~nameEs=?, ~region=?, ~kcal, ~protein, ~carbs, ~fat): Food.t => {
  id,
  nameEn,
  nameEs,
  region,
  provenance: Food.OpenData,
  kcal100g: kcal,
  protein100g: protein,
  carbs100g: carbs,
  fat100g: fat,
}

let minimal = food(
  ~id="8189c6c2-5a0d-5716-b6e9-c720038793da",
  ~nameEn="Rice",
  ~kcal=130.,
  ~protein=2.7,
  ~carbs=28.,
  ~fat=0.3,
)

let full = food(
  ~id="9ed18899-82c3-5836-90bb-605cf6d01605",
  ~nameEn="Black beans",
  ~nameEs="Frijoles negros",
  ~region="GT",
  ~kcal=341.,
  ~protein=21.6,
  ~carbs=62.4,
  ~fat=1.42,
)

testAsync("digests an empty dataset", async () => {
  let digest = await DatasetDigest.compute([])
  expect(digest)->toBe("bcdb29cbc7a081964f2fe9026c78a28f83df67c5069c1194939e93c0e4ed2843")
})

testAsync("digests a record without optional fields", async () => {
  let digest = await DatasetDigest.compute([minimal])
  expect(digest)->toBe("02067ceeeae0d55dbd1645aca208c184bc24060fcc3e096d178b3a709b0e89a9")
})

testAsync("digests a record with optional fields present", async () => {
  let digest = await DatasetDigest.compute([full])
  expect(digest)->toBe("f1f61cb84b13fcce36509bbbc2bee2ce9a0bae73d13f686b92616e75ac22575c")
})

testAsync("is independent of record order", async () => {
  // A client that applied a series of deltas holds its records in a different
  // order than one that ingested a snapshot; both must agree.
  let forward = await DatasetDigest.compute([minimal, full])
  let reversed = await DatasetDigest.compute([full, minimal])
  expect(forward)->toBe("bf78e0b2f9829f5e651520e03189b7acf5f65e665b5930a6facff788b2d638ca")
  expect(reversed)->toBe(forward)
})

testAsync("rounds nutrients to four decimals", async () => {
  let rounded = food(
    ~id="c8e288de-459e-5e50-aaa2-51e46caf77eb",
    ~nameEn="Rounded",
    ~kcal=1.00005,
    ~protein=0.,
    ~carbs=0.25,
    ~fat=0.,
  )
  let digest = await DatasetDigest.compute([rounded])
  expect(digest)->toBe("4dace445364690ffe5fe068ea67a82abc00ccde7b79da32e3daccfc483529bcc")
})

testAsync("rounds ties half up", async () => {
  // The case that broke a real cross-language check: k/32 values land exactly on
  // a tie at the 4th decimal, where Rust's `{:.4}` rounds to even but toFixed
  // rounds up. The contract mandates half-up, i.e. what toFixed already does —
  // so this pins the producer to the client, not the other way round.
  let tie = food(
    ~id="46619500-309c-5415-9d10-2db41d2c6634",
    ~nameEn="Tie",
    ~kcal=0.,
    ~protein=2.90625,
    ~carbs=0.65625,
    ~fat=0.,
  )
  let digest = await DatasetDigest.compute([tie])
  expect(digest)->toBe("2ad916b4c155a9f7884820f6f227e43a40554fccc1c3da6c4675a573a0830489")
})

testAsync("normalises negative zero", async () => {
  // Rust renders -0.0 as "-0.0000" while JS renders it as "0.0000"; the
  // encoding normalises so the two agree.
  let negZero = food(
    ~id="3a2836c6-6981-5076-820e-5ff2df696832",
    ~nameEn="NegZero",
    ~kcal=0.,
    ~protein=-0.,
    ~carbs=0.,
    ~fat=0.,
  )
  let digest = await DatasetDigest.compute([negZero])
  expect(digest)->toBe("c827f09113d8387aa80768960723bf446b60c4d6b60b2179e32f6de87b4330fc")
})

testAsync("length-prefixes multi-byte UTF-8 names by bytes, not characters", async () => {
  // Where a naive implementation using string length would diverge.
  let unicode = food(
    ~id="c2439561-eecc-5fe9-a950-1a6a397065e1",
    ~nameEn="Piñata café",
    ~nameEs="Piñata café ☕",
    ~region="CR",
    ~kcal=0.,
    ~protein=0.,
    ~carbs=0.,
    ~fat=0.,
  )
  let digest = await DatasetDigest.compute([unicode])
  expect(digest)->toBe("abad9584967a1ead7e07bf6099df735e30352507eafade8a4ebef6757bf56623")
})
