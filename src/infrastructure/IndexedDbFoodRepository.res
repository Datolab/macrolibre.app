// IndexedDB adapter implementing FoodRepository (ADR-0002). The `foods_local`
// store is keyed by id with a *multiEntry* index over the food's word tokens,
// so search matches any word by prefix (ADR-0006, <100 ms local search). Reads
// are decoded through FoodDecoder (ADR-0003) — nothing from IndexedDB is
// trusted as a domain type without decoding.

type db
type objectStore
type keyRange
type storeNames

@module("idb")
external openDB: (string, int, {"upgrade": db => unit}) => promise<db> = "openDB"
@get external objectStoreNames: db => storeNames = "objectStoreNames"
@send external listContains: (storeNames, string) => bool = "contains"
@send external deleteObjectStore: (db, string) => unit = "deleteObjectStore"
@send
external createObjectStore: (db, string, {"keyPath": string}) => objectStore = "createObjectStore"
@send
external createIndex: (objectStore, string, string, {"multiEntry": bool}) => unit = "createIndex"
@send external put: (db, string, JSON.t) => promise<JSON.t> = "put"
@send external deleteById: (db, string, string) => promise<unit> = "delete"
@send external getAll: (db, string) => promise<array<JSON.t>> = "getAll"
@send
external getAllFromIndex: (db, string, string, keyRange) => promise<array<JSON.t>> =
  "getAllFromIndex"
@send external dbCount: (db, string) => promise<int> = "count"
@val @scope("IDBKeyRange") external keyRangeBound: (string, string) => keyRange = "bound"

let storeName = "foods_local"
let indexName = "by_token"
let version = 2

let provenanceBadge = p =>
  switch p {
  | Food.Official => "official"
  | Food.DietitianVerified => "dietitian_verified"
  | Food.OpenData => "open_data"
  | Food.UserSubmitted => "user_submitted"
  }

// Encode a domain Food into its stored contract-shaped record, plus the word
// tokens (from both names) the multiEntry index is built on.
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
  let tokens = Array.concat(
    SearchKey.tokens(food.nameEn),
    food.nameEs->Option.mapOr([], SearchKey.tokens),
  )
  fields->Dict.set("search_tokens", JSON.Encode.array(tokens->Array.map(JSON.Encode.string)))
  JSON.Encode.object(fields)
}

let make = async (): FoodRepository.t => {
  let db = await openDB(
    "macrolibre",
    version,
    {
      "upgrade": db => {
        // Recreate the store so the token index applies to a fresh schema; the
        // app re-ingests when the store is empty.
        if db->objectStoreNames->listContains(storeName) {
          db->deleteObjectStore(storeName)
        }
        let store = db->createObjectStore(storeName, {"keyPath": "id"})
        store->createIndex(indexName, "search_tokens", {"multiEntry": true})
      },
    },
  )
  {
    upsertMany: async foods => {
      let _ = await Promise.all(foods->Array.map(food => db->put(storeName, toStoredJson(food))))
    },
    searchByName: async query => {
      let key = SearchKey.normalize(query)
      if key == "" {
        []
      } else {
        // Prefix range over the token index; a food with several matching tokens
        // comes back more than once, so dedupe by id.
        let range = keyRangeBound(key, key ++ String.fromCharCode(0xffff))
        let rows = await db->getAllFromIndex(storeName, indexName, range)
        let seen = Dict.make()
        rows->Array.filterMap(row =>
          switch FoodDecoder.decode(row) {
          | Ok(food) if seen->Dict.get(food.id)->Option.isNone => {
              seen->Dict.set(food.id, true)
              Some(food)
            }
          | _ => None
          }
        )
      }
    },
    count: async () => await db->dbCount(storeName),
    remove: async id => await db->deleteById(storeName, id),
    all: async () => {
      let rows = await db->getAll(storeName)
      rows->Array.filterMap(row =>
        switch FoodDecoder.decode(row) {
        | Ok(food) => Some(food)
        | Error(_) => None
        }
      )
    },
  }
}
