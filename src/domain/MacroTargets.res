// Daily macro targets (grams) derived from the calorie goal via a standard
// 30% protein / 40% carbs / 30% fat split (protein & carbs 4 kcal/g, fat 9).
// The rings fill toward these.
type t = {
  protein: float,
  carbs: float,
  fat: float,
}

let fromCalories = (kcal: int): t => {
  let k = kcal->Int.toFloat
  {
    protein: 0.3 *. k /. 4.,
    carbs: 0.4 *. k /. 4.,
    fat: 0.3 *. k /. 9.,
  }
}
