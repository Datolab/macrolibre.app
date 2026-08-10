// IndexedDB adapter implementing TemplateRepository. The `templates` store is
// keyed by id; each row's items array is stored inline (no separate store —
// items only ever load/save with their template). Reads are decoded (ADR-0003).
type db

@module("idb")
external openDB: (string, int, {"upgrade": db => unit}) => promise<db> = "openDB"
@send
external createObjectStore: (db, string, {"keyPath": string}) => unit = "createObjectStore"
@send external put: (db, string, JSON.t) => promise<JSON.t> = "put"
@send external deleteById: (db, string, string) => promise<unit> = "delete"
@send external getAll: (db, string) => promise<array<JSON.t>> = "getAll"

let storeName = "templates"

let itemToJson = (item: MealTemplate.item): JSON.t => {
  let fields = Dict.make()
  fields->Dict.set("food_id", JSON.Encode.string(item.foodId))
  fields->Dict.set("food_name", JSON.Encode.string(item.foodName))
  fields->Dict.set("grams", JSON.Encode.float(item.grams))
  fields->Dict.set("kcal", JSON.Encode.float(item.macros.kcal))
  fields->Dict.set("protein", JSON.Encode.float(item.macros.protein))
  fields->Dict.set("carbs", JSON.Encode.float(item.macros.carbs))
  fields->Dict.set("fat", JSON.Encode.float(item.macros.fat))
  JSON.Encode.object(fields)
}

let itemFromJson = (json: JSON.t): option<MealTemplate.item> =>
  switch json->JSON.Decode.object {
  | None => None
  | Some(obj) => {
      let str = k => obj->Dict.get(k)->Option.flatMap(JSON.Decode.string)
      let num = k => obj->Dict.get(k)->Option.flatMap(JSON.Decode.float)
      switch (str("food_id"), str("food_name"), num("grams"), num("kcal"), num("protein"), num("carbs"), num("fat")) {
      | (Some(foodId), Some(foodName), Some(grams), Some(kcal), Some(protein), Some(carbs), Some(fat)) =>
        Some({MealTemplate.foodId, foodName, grams, macros: {Macros.kcal, protein, carbs, fat}})
      | _ => None
      }
    }
  }

let toJson = (template: MealTemplate.t): JSON.t => {
  let fields = Dict.make()
  fields->Dict.set("id", JSON.Encode.string(template.id))
  fields->Dict.set("name", JSON.Encode.string(template.name))
  fields->Dict.set("items", JSON.Encode.array(template.items->Array.map(itemToJson)))
  JSON.Encode.object(fields)
}

let fromJson = (json: JSON.t): option<MealTemplate.t> =>
  switch json->JSON.Decode.object {
  | None => None
  | Some(obj) => {
      let str = k => obj->Dict.get(k)->Option.flatMap(JSON.Decode.string)
      let items =
        obj
        ->Dict.get("items")
        ->Option.flatMap(JSON.Decode.array)
        ->Option.mapOr([], arr => arr->Array.filterMap(itemFromJson))
      switch (str("id"), str("name")) {
      | (Some(id), Some(name)) => Some({MealTemplate.id, name, items})
      | _ => None
      }
    }
  }

let make = async (): TemplateRepository.t => {
  let db = await openDB(
    "macrolibre-templates",
    1,
    {
      "upgrade": db => db->createObjectStore(storeName, {"keyPath": "id"}),
    },
  )
  {
    add: async template => {
      let _ = await db->put(storeName, toJson(template))
    },
    listAll: async () => {
      let rows = await db->getAll(storeName)
      rows->Array.filterMap(fromJson)
    },
    remove: async id => await db->deleteById(storeName, id),
  }
}
