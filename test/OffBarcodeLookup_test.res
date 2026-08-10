open Vitest

let found = `{"status":1,"product":{"product_name":"Nutella","product_name_es":"Nutella","nutriments":{"energy-kcal_100g":539,"proteins_100g":6.3,"carbohydrates_100g":57.5,"fat_100g":30.9}}}`

test("decodes a found product into a food", () => {
  switch OffBarcodeLookup.decodeProduct(JSON.parseExn(found), ~id="b1") {
  | Some(food) => {
      expect(food.nameEn)->toBe("Nutella")
      expect(food.kcal100g)->toBe(539.)
      expect(food.protein100g)->toBe(6.3)
      expect(food.provenance)->toEqual(Food.OpenData)
    }
  | None => expect(false)->toBe(true)
  }
})

test("returns None when the product is not found or has no name/energy", () => {
  let notFound = OffBarcodeLookup.decodeProduct(JSON.parseExn(`{"status":0}`), ~id="b1")
  let noEnergy = OffBarcodeLookup.decodeProduct(
    JSON.parseExn(`{"status":1,"product":{"product_name":"X","nutriments":{}}}`),
    ~id="b1",
  )
  expect(notFound->Option.isNone)->toBe(true)
  expect(noEnergy->Option.isNone)->toBe(true)
})
