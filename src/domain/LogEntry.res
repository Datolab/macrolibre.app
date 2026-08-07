// One logged food (SRS FOOD_LOG). Macros are denormalized at log time so the
// entry reflects what was eaten even if the food record later changes.
type t = {
  id: string,
  foodName: string,
  grams: float,
  macros: Macros.t,
  day: string, // YYYY-MM-DD
}
