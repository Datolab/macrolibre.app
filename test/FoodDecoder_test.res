open Vitest

let parse = JSON.parseExn

test("decodes a valid open_data food line", () => {
  let json = parse(
    `{"id":"abc","name_en":"Rice","region":"GT","provenance_badge":"open_data","kcal_100g":130,"protein_100g":2.7,"carbs_100g":28,"fat_100g":0.3}`,
  )
  switch FoodDecoder.decode(json) {
  | Ok(food) => {
      expect(food.nameEn)->toBe("Rice")
      expect(food.region)->toEqual(Some("GT"))
      expect(food.provenance)->toEqual(Food.OpenData)
    }
  | Error(_) => expect(false)->toBe(true)
  }
})

test("rejects a line missing required macros", () => {
  let json = parse(`{"id":"abc","name_en":"Rice","provenance_badge":"open_data"}`)
  switch FoodDecoder.decode(json) {
  | Ok(_) => expect(false)->toBe(true)
  | Error(_) => expect(true)->toBe(true)
  }
})

test("rejects a non-object line", () => {
  switch FoodDecoder.decode(parse(`"nope"`)) {
  | Ok(_) => expect(false)->toBe(true)
  | Error(_) => expect(true)->toBe(true)
  }
})
