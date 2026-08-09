// IndexedDB adapter implementing LogRepository. The `logs` store is keyed by id
// with an index on `day` for the "today" view. Reads are decoded (ADR-0003).
type db
type objectStore
type keyRange

@module("idb")
external openDB: (string, int, {"upgrade": db => unit}) => promise<db> = "openDB"
@send
external createObjectStore: (db, string, {"keyPath": string}) => objectStore = "createObjectStore"
@send external createIndex: (objectStore, string, string) => unit = "createIndex"
@send external put: (db, string, JSON.t) => promise<JSON.t> = "put"
@send external deleteById: (db, string, string) => promise<unit> = "delete"
@send external getAll: (db, string) => promise<array<JSON.t>> = "getAll"
@send
external getAllFromIndex: (db, string, string, keyRange) => promise<array<JSON.t>> =
  "getAllFromIndex"
@val @scope("IDBKeyRange") external keyRangeOnly: string => keyRange = "only"

let storeName = "logs"
let indexName = "by_day"

let toJson = (entry: LogEntry.t): JSON.t => {
  let fields = Dict.make()
  fields->Dict.set("id", JSON.Encode.string(entry.id))
  fields->Dict.set("food_name", JSON.Encode.string(entry.foodName))
  fields->Dict.set("grams", JSON.Encode.float(entry.grams))
  fields->Dict.set("kcal", JSON.Encode.float(entry.macros.kcal))
  fields->Dict.set("protein", JSON.Encode.float(entry.macros.protein))
  fields->Dict.set("carbs", JSON.Encode.float(entry.macros.carbs))
  fields->Dict.set("fat", JSON.Encode.float(entry.macros.fat))
  fields->Dict.set("day", JSON.Encode.string(entry.day))
  fields->Dict.set("logged_at", JSON.Encode.float(entry.loggedAt))
  JSON.Encode.object(fields)
}

let fromJson = (json: JSON.t): option<LogEntry.t> => {
  switch json->JSON.Decode.object {
  | None => None
  | Some(obj) => {
      let str = k => obj->Dict.get(k)->Option.flatMap(JSON.Decode.string)
      let num = k => obj->Dict.get(k)->Option.flatMap(JSON.Decode.float)
      // Older entries predate logged_at; default to 0 so they still decode.
      let loggedAt = num("logged_at")->Option.getOr(0.)
      switch (
        str("id"),
        str("food_name"),
        num("grams"),
        num("kcal"),
        num("protein"),
        num("carbs"),
        num("fat"),
        str("day"),
      ) {
      | (
          Some(id),
          Some(foodName),
          Some(grams),
          Some(kcal),
          Some(protein),
          Some(carbs),
          Some(fat),
          Some(day),
        ) =>
        Some({
          LogEntry.id,
          foodName,
          grams,
          macros: {Macros.kcal, protein, carbs, fat},
          day,
          loggedAt,
        })
      | _ => None
      }
    }
  }
}

let make = async (): LogRepository.t => {
  let db = await openDB(
    "macrolibre-logs",
    1,
    {
      "upgrade": db => {
        let store = db->createObjectStore(storeName, {"keyPath": "id"})
        store->createIndex(indexName, "day")
      },
    },
  )
  {
    add: async entry => {
      let _ = await db->put(storeName, toJson(entry))
    },
    listByDay: async day => {
      let rows = await db->getAllFromIndex(storeName, indexName, keyRangeOnly(day))
      rows->Array.filterMap(fromJson)
    },
    remove: async id => await db->deleteById(storeName, id),
    recent: async limit => {
      let all = (await db->getAll(storeName))->Array.filterMap(fromJson)
      let byRecency = all->Array.toSorted((a, b) => Float.compare(b.loggedAt, a.loggedAt))
      // Keep the most recent entry per distinct food name.
      let seen = Dict.make()
      let unique = []
      byRecency->Array.forEach(entry =>
        if seen->Dict.get(entry.foodName)->Option.isNone {
          seen->Dict.set(entry.foodName, true)
          unique->Array.push(entry)
        }
      )
      unique->Array.slice(~start=0, ~end=limit)
    },
  }
}
