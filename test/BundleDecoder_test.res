open Vitest

let line = (id, name) =>
  `{"id":"${id}","name_en":"${name}","provenance_badge":"open_data","kcal_100g":130,"protein_100g":2.7,"carbs_100g":28,"fat_100g":0.3}`

test("decodes valid lines and counts the rejects", () => {
  let ndjson =
    [
      line("1", "Rice"),
      `not json`,
      `{"id":"2","name_en":"Beans","provenance_badge":"open_data"}`, // missing macros
      line("3", "Tortilla"),
    ]->Array.join("\n")

  let result = BundleDecoder.decodeNdjson(ndjson)
  expect(Array.length(result.foods))->toBe(2)
  expect(result.rejected)->toBe(2)
})

test("ignores blank lines", () => {
  let ndjson = [line("1", "Rice"), ``, `   `]->Array.join("\n")
  let result = BundleDecoder.decodeNdjson(ndjson)
  expect(Array.length(result.foods))->toBe(1)
  expect(result.rejected)->toBe(0)
})
