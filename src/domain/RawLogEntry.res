// Builds a one-off logged entry directly from raw macros the user enters
// (FR-A-5: quick-add kcal + P/C/F with no database entry). No Food record is
// created or searched — this never touches foods_local, only the day's log.
// An unlabeled entry gets a generic name rather than being rejected.
let build = (
  ~id: string,
  ~name: string,
  ~kcal: float,
  ~protein: float,
  ~carbs: float,
  ~fat: float,
  ~day: string,
  ~loggedAt: float,
): option<LogEntry.t> => {
  let macrosOk = [kcal, protein, carbs, fat]->Array.every(v => Float.isFinite(v) && v >= 0.)
  if !macrosOk {
    None
  } else {
    let trimmed = String.trim(name)
    Some({
      LogEntry.id,
      foodName: trimmed == "" ? "Quick add" : trimmed,
      grams: 100.,
      macros: {Macros.kcal, protein, carbs, fat},
      day,
      loggedAt,
    })
  }
}
