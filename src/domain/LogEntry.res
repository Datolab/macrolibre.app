// One logged food (SRS FOOD_LOG). Macros are denormalized at log time so the
// entry reflects what was eaten even if the food record later changes.
type t = {
  id: string,
  foodName: string,
  grams: float,
  macros: Macros.t,
  day: string, // YYYY-MM-DD
  loggedAt: float, // epoch ms, for recency ordering
}

// Change the logged quantity, rescaling the macros proportionally. No need for
// the original food — the stored macros are the basis.
let rescale = (entry: t, newGrams: float): t => {
  let factor = entry.grams > 0. ? newGrams /. entry.grams : 0.
  {...entry, grams: newGrams, macros: Macros.scale(entry.macros, factor)}
}
