// IndexedDB adapter implementing FoodRepository (ADR-0002). The `foods_local`
// store is keyed by id with an index on a normalized search key for <100 ms
// local search (ADR-0006). Reads are decoded through FoodDecoder (ADR-0003) —
// nothing from IndexedDB is trusted as a domain type without decoding.

type db
type objectStore
type keyRange

@module("idb")
external openDB: (string, int, {"upgrade": db => unit}) => promise<db> = "openDB"
@send
external createObjectStore: (db, string, {"keyPath": string}) => objectStore = "createObjectStore"
@send external createIndex: (objectStore, string, string) => unit = "createIndex"
@send external put: (db, string, JSON.t) => promise<JSON.t> = "put"
@send
external getAllFromIndex: (db, string, string, keyRange) => promise<array<JSON.t>> =
  "getAllFromIndex"
@send external dbCount: (db, string) => promise<int> = "count"
@val @scope("IDBKeyRange") external keyRangeBound: (string, string) => keyRange = "bound"

let storeName = "foods_local"
let indexName = "by_search_key"

let provenanceBadge = p =>
  switch p {
  | Food.Official => "official"
  | Food.DietitianVerified => "dietitian_verified"
  | Food.OpenData => "open_data"
  | Food.UserSubmitted => "user_submitted"
  }

// Encode a domain Food into its stored contract-shaped record, plus the
// normalized `search_key` the index is built on.
let toStoredJson = (food: Food.t): JSON.t => {
  let fields = Dict.make()
  fields->Dict.set("id", JSON.Encode.string(food.id))
  fields->Dict.set("name_en", JSON.Encode.string(food.nameEn))
  food.nameEs->Option.forEach(v => fields->Dict.set("name_es", JSON.Encode.string(v)))
  food.region->Option.forEach(v => fields->Dict.set("region", JSON.Encode.string(v)))
  fields->Dict.set("provenance_badge", JSON.Encode.string(provenanceBadge(food.provenance)))
  fields->Dict.set("kcal_100g", JSON.Encode.float(food.kcal100g))
  fields->Dict.set("protein_100g", JSON.Encode.float(food.protein100g))
  fields->Dict.set("carbs_100g", JSON.Encode.float(food.carbs100g))
  fields->Dict.set("fat_100g", JSON.Encode.float(food.fat100g))
  fields->Dict.set("search_key", JSON.Encode.string(SearchKey.normalize(food.nameEn)))
  JSON.Encode.object(fields)
}

let make = async (): FoodRepository.t => {
  let db = await openDB(
    "macrolibre",
    1,
    {
      "upgrade": db => {
        let store = db->createObjectStore(storeName, {"keyPath": "id"})
        store->createIndex(indexName, "search_key")
      },
    },
  )
  {
    upsertMany: async foods => {
      let _ = await Promise.all(foods->Array.map(food => db->put(storeName, toStoredJson(food))))
    },
    searchByName: async query => {
      let key = SearchKey.normalize(query)
      // Prefix range [key, key + high sentinel): all keys starting with `key`.
      let range = keyRangeBound(key, key ++ String.fromCharCode(0xffff))
      let rows = await db->getAllFromIndex(storeName, indexName, range)
      rows->Array.filterMap(row =>
        switch FoodDecoder.decode(row) {
        | Ok(food) => Some(food)
        | Error(_) => None
        }
      )
    },
    count: async () => await db->dbCount(storeName),
  }
}
