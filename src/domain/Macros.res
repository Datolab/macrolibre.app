// Macronutrient totals (kcal + grams). Pure domain arithmetic — scaling a
// food's per-100g values to a logged quantity, and summing a day's entries.
type t = {
  kcal: float,
  protein: float,
  carbs: float,
  fat: float,
}

let zero = {kcal: 0., protein: 0., carbs: 0., fat: 0.}

let forQuantity = (food: Food.t, grams: float): t => {
  let factor = grams /. 100.
  {
    kcal: food.kcal100g *. factor,
    protein: food.protein100g *. factor,
    carbs: food.carbs100g *. factor,
    fat: food.fat100g *. factor,
  }
}

let add = (a: t, b: t): t => {
  kcal: a.kcal +. b.kcal,
  protein: a.protein +. b.protein,
  carbs: a.carbs +. b.carbs,
  fat: a.fat +. b.fat,
}

let sum = (items: array<t>): t => items->Array.reduce(zero, add)
