// Use case: log a food at a given quantity. Computes the macros for the amount
// eaten and persists the entry via the LogRepository port. No I/O of its own.
let run = async (
  ~repository: LogRepository.t,
  ~id: string,
  ~food: Food.t,
  ~grams: float,
  ~day: string,
  ~loggedAt: float,
): LogEntry.t => {
  let entry: LogEntry.t = {
    id,
    foodName: food.nameEn,
    grams,
    macros: Macros.forQuantity(food, grams),
    day,
    loggedAt,
  }
  await repository.add(entry)
  entry
}
