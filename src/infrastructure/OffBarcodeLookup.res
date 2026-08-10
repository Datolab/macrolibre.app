// BarcodeLookup backed by the Open Food Facts online API. The offline bundle is
// a curated subset, so barcode scans (which need the full product DB) go online.
// The response is decoded at the boundary (ADR-0003); a missing/invalid product
// or a network error yields None, never an exception.
type response
@val external fetch: string => promise<response> = "fetch"
@send external json: response => promise<JSON.t> = "json"

// Decode an OFF `/api/v2/product/{barcode}.json` response into a domain Food.
// Pure — tested with fixtures. Requires a product name and a per-100g energy;
// missing macros default to 0.
let decodeProduct = (json: JSON.t, ~id: string): option<Food.t> => {
  switch json->JSON.Decode.object {
  | None => None
  | Some(root) =>
    switch root->Dict.get("status")->Option.flatMap(JSON.Decode.float) {
    | Some(1.) =>
      switch root->Dict.get("product")->Option.flatMap(JSON.Decode.object) {
      | None => None
      | Some(product) => {
          let str = k => product->Dict.get(k)->Option.flatMap(JSON.Decode.string)
          let nutriments =
            product->Dict.get("nutriments")->Option.flatMap(JSON.Decode.object)->Option.getOr(Dict.make())
          let num = k => nutriments->Dict.get(k)->Option.flatMap(JSON.Decode.float)
          switch (str("product_name"), num("energy-kcal_100g")) {
          | (Some(name), Some(kcal)) if String.trim(name) != "" =>
            Some({
              Food.id,
              nameEn: String.trim(name),
              nameEs: str("product_name_es")->Option.map(String.trim),
              region: None,
              provenance: Food.OpenData,
              kcal100g: kcal,
              protein100g: num("proteins_100g")->Option.getOr(0.),
              carbs100g: num("carbohydrates_100g")->Option.getOr(0.),
              fat100g: num("fat_100g")->Option.getOr(0.),
            })
          | _ => None
          }
        }
      }
    | _ => None // status 0 = not found
    }
  }
}

let make = (): BarcodeLookup.t => {
  {
    lookup: async barcode =>
      try {
        let url =
          `https://world.openfoodfacts.org/api/v2/product/${barcode}.json?fields=product_name,product_name_es,nutriments`
        let response = await fetch(url)
        let data = await response->json
        decodeProduct(data, ~id="barcode-" ++ barcode)
      } catch {
      | _ => None
      },
  }
}
