// Deterministic, food-independent portion units (FR-A-7). Regional volumetric
// measures (unidad, taza, cucharada) aren't included yet — converting them
// accurately needs a per-food serving weight the bundled dataset doesn't
// carry; only grams/oz convert the same way for every food.
type t = Grams | Ounces

let toGrams = (unit: t, quantity: float): float =>
  switch unit {
  | Grams => quantity
  | Ounces => quantity *. 28.3495
  }

let label = (unit: t): string =>
  switch unit {
  | Grams => "g"
  | Ounces => "oz"
  }
