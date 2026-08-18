open Vitest

let food = (~id, ~nameEn, ~kcal): Food.t => {
  id,
  nameEn,
  nameEs: None,
  region: None,
  provenance: Food.OpenData,
  kcal100g: kcal,
  protein100g: 0.,
  carbs100g: kcal /. 4.,
  fat100g: 0.,
}

let rice = food(~id="8189c6c2-5a0d-5716-b6e9-c720038793da", ~nameEn="Rice", ~kcal=130.)
let beans = food(~id="9ed18899-82c3-5836-90bb-605cf6d01605", ~nameEn="Beans", ~kcal=90.)
let corn = food(~id="c8e288de-459e-5e50-aaa2-51e46caf77eb", ~nameEn="Corn", ~kcal=80.)

// A fake repository recording writes, so a rejected delta is provably a no-op.
let makeRepo = (initial: array<Food.t>) => {
  let stored = ref(initial)
  let writes = ref(0)
  let repo: FoodRepository.t = {
    upsertMany: async foods => {
      writes := writes.contents + 1
      foods->Array.forEach(food => {
        let without = stored.contents->Array.filter(f => f.Food.id != food.Food.id)
        stored := Array.concat(without, [food])
      })
    },
    remove: async id => {
      writes := writes.contents + 1
      stored := stored.contents->Array.filter(f => f.Food.id != id)
    },
    all: async () => stored.contents,
    searchByName: async _ => [],
    count: async () => Array.length(stored.contents),
  }
  (repo, stored, writes)
}

let delta = (~from=Some("v2026.08"), ~checksum, ~changed, ~removed): DatasetDelta.t => {
  fromVersion: from,
  toVersion: "v2026.09",
  layer: "open",
  checksum,
  signature: "sig",
  changed,
  removed,
}

testAsync("applies changed records and removes tombstoned ones", async () => {
  let (repo, stored, _) = makeRepo([rice, beans])
  let updatedRice = {...rice, kcal100g: 140., carbs100g: 35.}
  // Expected result: updated Rice + new Corn, with Beans deleted.
  let expected = await DatasetDigest.compute([updatedRice, corn])

  let outcome = await ApplyDelta.run(
    ~repository=repo,
    ~delta=delta(~checksum=expected, ~changed=[updatedRice, corn], ~removed=[beans.id]),
  )

  switch outcome {
  | ApplyDelta.Applied({version, recordCount}) => {
      expect(version)->toBe("v2026.09")
      expect(recordCount)->toBe(2)
    }
  | Rejected(reason) => {
      Console.log(reason)
      expect(false)->toBe(true)
    }
  }
  let names = stored.contents->Array.map(f => f.Food.nameEn)->Array.toSorted(String.compare)
  expect(names)->toEqual(["Corn", "Rice"])
})

testAsync("writes nothing when the resulting digest does not match", async () => {
  // FR-C-5: rather than apply and then roll back, verify first and never write —
  // a partially-applied delta is the corruption we are trying to avoid.
  let (repo, stored, writes) = makeRepo([rice, beans])

  let outcome = await ApplyDelta.run(
    ~repository=repo,
    ~delta=delta(~checksum="0000000000000000000000000000000000000000000000000000000000000000", ~changed=[corn], ~removed=[]),
  )

  expect(
    switch outcome {
    | ApplyDelta.Rejected(_) => true
    | Applied(_) => false
    },
  )->toBe(true)
  expect(writes.contents)->toBe(0)
  let names = stored.contents->Array.map(f => f.Food.nameEn)->Array.toSorted(String.compare)
  expect(names)->toEqual(["Beans", "Rice"])
})

testAsync("a full snapshot replaces the whole dataset", async () => {
  // from_version null means "replace", so records absent from the snapshot go
  // away even though they aren't listed as removed.
  let (repo, stored, _) = makeRepo([rice, beans])
  let expected = await DatasetDigest.compute([corn])

  let outcome = await ApplyDelta.run(
    ~repository=repo,
    ~delta=delta(~from=None, ~checksum=expected, ~changed=[corn], ~removed=[]),
  )

  expect(
    switch outcome {
    | ApplyDelta.Applied(_) => true
    | Rejected(_) => false
    },
  )->toBe(true)
  expect(stored.contents->Array.map(f => f.Food.nameEn))->toEqual(["Corn"])
})

testAsync("an empty delta is applied as a no-op that still verifies", async () => {
  let (repo, stored, _) = makeRepo([rice, beans])
  let expected = await DatasetDigest.compute([rice, beans])

  let outcome = await ApplyDelta.run(
    ~repository=repo,
    ~delta=delta(~checksum=expected, ~changed=[], ~removed=[]),
  )

  expect(
    switch outcome {
    | ApplyDelta.Applied({recordCount}) => recordCount == 2
    | Rejected(_) => false
    },
  )->toBe(true)
  expect(Array.length(stored.contents))->toBe(2)
})
