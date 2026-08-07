// Decodes open base bundle text (NDJSON, ADR-0006/0007) into domain foods, one
// line at a time via the FoodDecoder boundary decoder. A malformed line is
// counted and skipped, never fatal (ADR-0003) — a single bad record must not
// abort ingestion of the whole bundle.
type result = {
  foods: array<Food.t>,
  rejected: int,
}

let decodeNdjson = (text: string): result => {
  let foods = []
  let rejected = ref(0)
  text
  ->String.split("\n")
  ->Array.forEach(line => {
    let trimmed = String.trim(line)
    if trimmed !== "" {
      let parsed = try Some(JSON.parseExn(trimmed)) catch {
      | _ => None
      }
      switch parsed {
      | Some(json) =>
        switch FoodDecoder.decode(json) {
        | Ok(food) => foods->Array.push(food)
        | Error(_) => rejected := rejected.contents + 1
        }
      | None => rejected := rejected.contents + 1
      }
    }
  })
  {foods, rejected: rejected.contents}
}
