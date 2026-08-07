// Boundary decoder (ADR-0003): turns one raw JSON value — a line of the open
// base bundle (ADR-0006/0007) or an API response — into a domain `Food.t`.
// Never coerces JSON directly into the domain type; a bad shape yields a typed
// `Error` the caller must branch on, never an exception.

type decodeError = {field: string, reason: string}

let decode = (json: JSON.t): result<Food.t, decodeError> => {
  switch json->JSON.Decode.object {
  | None => Error({field: "$", reason: "expected a JSON object"})
  | Some(obj) => {
      let str = name => obj->Dict.get(name)->Option.flatMap(JSON.Decode.string)
      let num = name => obj->Dict.get(name)->Option.flatMap(JSON.Decode.float)

      let provenance =
        str("provenance_badge")->Option.flatMap(badge =>
          switch badge {
          | "official" => Some(Food.Official)
          | "dietitian_verified" => Some(Food.DietitianVerified)
          | "open_data" => Some(Food.OpenData)
          | "user_submitted" => Some(Food.UserSubmitted)
          | _ => None
          }
        )

      switch (
        str("id"),
        str("name_en"),
        provenance,
        num("kcal_100g"),
        num("protein_100g"),
        num("carbs_100g"),
        num("fat_100g"),
      ) {
      | (Some(id), Some(nameEn), Some(prov), Some(kcal), Some(protein), Some(carbs), Some(fat)) =>
        Ok(
          (
            {
              id,
              nameEn,
              nameEs: str("name_es"),
              region: str("region"),
              provenance: prov,
              kcal100g: kcal,
              protein100g: protein,
              carbs100g: carbs,
              fat100g: fat,
            }: Food.t
          ),
        )
      | _ => Error({field: "?", reason: "missing or invalid required field"})
      }
    }
  }
}
