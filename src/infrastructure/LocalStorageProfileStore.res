// ProfileStore backed by localStorage. Encodes/decodes the profile as JSON;
// a corrupt or missing value decodes to None (ADR-0003 — decode, don't trust).
@val @scope("localStorage") external getItem: string => Nullable.t<string> = "getItem"
@val @scope("localStorage") external setItem: (string, string) => unit = "setItem"

let key = "macrolibre.profile"

let encode = (profile: Profile.t): string => {
  let fields = Dict.make()
  fields->Dict.set("height_cm", JSON.Encode.float(profile.heightCm))
  fields->Dict.set("weight_kg", JSON.Encode.float(profile.weightKg))
  fields->Dict.set("goal", JSON.Encode.string(Goal.toString(profile.goal)))
  fields->Dict.set("kcal_goal", JSON.Encode.float(profile.kcalGoal->Int.toFloat))
  JSON.Encode.object(fields)->JSON.stringify
}

let decode = (raw: string): option<Profile.t> => {
  let json = try Some(JSON.parseExn(raw)) catch {
  | _ => None
  }
  switch json->Option.flatMap(JSON.Decode.object) {
  | None => None
  | Some(obj) => {
      let num = k => obj->Dict.get(k)->Option.flatMap(JSON.Decode.float)
      let goal = obj->Dict.get("goal")->Option.flatMap(JSON.Decode.string)->Option.flatMap(Goal.fromString)
      switch (num("height_cm"), num("weight_kg"), goal, num("kcal_goal")) {
      | (Some(heightCm), Some(weightKg), Some(goal), Some(kcalGoal)) =>
        Some({Profile.heightCm: heightCm, weightKg, goal, kcalGoal: kcalGoal->Int.fromFloat})
      | _ => None
      }
    }
  }
}

let make = (): ProfileStore.t => {
  {
    load: () => getItem(key)->Nullable.toOption->Option.flatMap(decode),
    save: profile => setItem(key, encode(profile)),
  }
}
