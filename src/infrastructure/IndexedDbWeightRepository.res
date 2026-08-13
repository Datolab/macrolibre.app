// IndexedDB adapter implementing WeightRepository. The `weights` store is
// keyed by `day` directly (not a synthetic id) — one weigh-in per day is the
// natural model, so a second `record` for the same day upserts in place.
type db

@module("idb")
external openDB: (string, int, {"upgrade": db => unit}) => promise<db> = "openDB"
@send
external createObjectStore: (db, string, {"keyPath": string}) => unit = "createObjectStore"
@send external put: (db, string, JSON.t) => promise<JSON.t> = "put"
@send external getAll: (db, string) => promise<array<JSON.t>> = "getAll"

let storeName = "weights"

let toJson = (entry: WeightEntry.t): JSON.t => {
  let fields = Dict.make()
  fields->Dict.set("day", JSON.Encode.string(entry.day))
  fields->Dict.set("kg", JSON.Encode.float(entry.kg))
  fields->Dict.set("logged_at", JSON.Encode.float(entry.loggedAt))
  JSON.Encode.object(fields)
}

let fromJson = (json: JSON.t): option<WeightEntry.t> =>
  switch json->JSON.Decode.object {
  | None => None
  | Some(obj) => {
      let day = obj->Dict.get("day")->Option.flatMap(JSON.Decode.string)
      let kg = obj->Dict.get("kg")->Option.flatMap(JSON.Decode.float)
      let loggedAt = obj->Dict.get("logged_at")->Option.flatMap(JSON.Decode.float)
      switch (day, kg, loggedAt) {
      | (Some(day), Some(kg), Some(loggedAt)) => Some({WeightEntry.day, kg, loggedAt})
      | _ => None
      }
    }
  }

let make = async (): WeightRepository.t => {
  let db = await openDB(
    "macrolibre-weights",
    1,
    {
      "upgrade": db => db->createObjectStore(storeName, {"keyPath": "day"}),
    },
  )
  {
    record: async entry => {
      let _ = await db->put(storeName, toJson(entry))
    },
    listAll: async () => {
      let rows = await db->getAll(storeName)
      rows->Array.filterMap(fromJson)
    },
  }
}
