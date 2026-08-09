// Builds a user-created food (FR-A custom foods). Validates the inputs before a
// domain `Food.t` can exist: a non-empty name and non-negative, finite macros.
// Provenance is `user_submitted`; it lives in the same store as open-base foods.
let build = (
  ~id: string,
  ~name: string,
  ~kcal: float,
  ~protein: float,
  ~carbs: float,
  ~fat: float,
): option<Food.t> => {
  let trimmed = String.trim(name)
  let macrosOk = [kcal, protein, carbs, fat]->Array.every(v => Float.isFinite(v) && v >= 0.)
  if trimmed == "" || !macrosOk {
    None
  } else {
    Some({
      Food.id,
      nameEn: trimmed,
      nameEs: None,
      region: None,
      provenance: Food.UserSubmitted,
      kcal100g: kcal,
      protein100g: protein,
      carbs100g: carbs,
      fat100g: fat,
    })
  }
}
