// Use case: log every item of a saved MealTemplate at once (FR-A: "log
// several foods at once"). Each item's macros were already denormalized when
// the template was built (MealTemplate), so this just turns them into
// LogEntry rows and persists them — no Food lookup, no recomputation.
let run = async (
  ~repository: LogRepository.t,
  ~template: MealTemplate.t,
  ~ids: array<string>,
  ~day: string,
  ~loggedAt: float,
): array<LogEntry.t> => {
  let entries = template.items->Array.mapWithIndex((item: MealTemplate.item, i): LogEntry.t => {
    id: ids->Array.getUnsafe(i),
    foodName: item.foodName,
    grams: item.grams,
    macros: item.macros,
    day,
    loggedAt,
  })
  await entries->Array.map(repository.add)->Promise.all->Promise.thenResolve(_ => ())
  entries
}
