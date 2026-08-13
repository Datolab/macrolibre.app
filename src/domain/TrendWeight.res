// Exponentially smoothed body weight (FR-D-2), the "Hacker's Diet"/trend-weight
// convention: alpha=0.1 is roughly a 10-day time constant, damping day-to-day
// water-weight noise without lagging real change for weeks. Named default, not
// SRS-mandated — easy to find and tune here if it needs adjusting.
let defaultAlpha = 0.1

let step = (~previous: option<float>, ~observedKg: float, ~alpha: float=defaultAlpha): float =>
  switch previous {
  | None => observedKg
  | Some(prev) => prev +. alpha *. (observedKg -. prev)
  }

// Folds a day-ascending series of weigh-ins into (day, trendKg) pairs.
let series = (entries: array<WeightEntry.t>, ~alpha: float=defaultAlpha): array<(string, float)> => {
  let previous = ref(None)
  entries->Array.map((entry: WeightEntry.t) => {
    let trend = step(~previous=previous.contents, ~observedKg=entry.kg, ~alpha)
    previous := Some(trend)
    (entry.day, trend)
  })
}
