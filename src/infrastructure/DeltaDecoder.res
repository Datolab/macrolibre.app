// Boundary decoder (ADR-0003) for the contract's `DatasetDelta` payload. A delta
// is applied unattended, so a malformed one must never become a domain value:
// decoding is all-or-nothing. In particular a single undecodable record in
// `changed` fails the whole delta rather than being skipped — silently dropping
// records would leave the dataset short and then fail the digest check for a
// confusing, unrelated-looking reason.

type decodeError = {field: string, reason: string}

let decode = (json: JSON.t): result<DatasetDelta.t, decodeError> => {
  switch json->JSON.Decode.object {
  | None => Error({field: "$", reason: "expected a JSON object"})
  | Some(obj) => {
      let str = name => obj->Dict.get(name)->Option.flatMap(JSON.Decode.string)
      let arr = name => obj->Dict.get(name)->Option.flatMap(JSON.Decode.array)

      // Present-but-null is a full snapshot; entirely absent is malformed.
      let fromVersion = switch obj->Dict.get("from_version") {
      | None => Error({field: "from_version", reason: "missing"})
      | Some(value) =>
        switch value->JSON.Decode.null {
        | Some(_) => Ok(None)
        | None =>
          switch value->JSON.Decode.string {
          | Some(v) => Ok(Some(v))
          | None => Error({field: "from_version", reason: "expected a string or null"})
          }
        }
      }

      let changed = switch arr("changed") {
      | None => Error({field: "changed", reason: "missing or not an array"})
      | Some(items) =>
        items->Array.reduce(Ok([]), (acc, item) =>
          switch acc {
          | Error(e) => Error(e)
          | Ok(foods) =>
            switch FoodDecoder.decode(item) {
            | Ok(food) => {
                foods->Array.push(food)
                Ok(foods)
              }
            | Error(e) => Error({field: "changed." ++ e.field, reason: e.reason})
            }
          }
        )
      }

      let removed = switch arr("removed") {
      | None => Error({field: "removed", reason: "missing or not an array"})
      | Some(items) =>
        items->Array.reduce(Ok([]), (acc, item) =>
          switch acc {
          | Error(e) => Error(e)
          | Ok(ids) =>
            switch item->JSON.Decode.string {
            | Some(id) => {
                ids->Array.push(id)
                Ok(ids)
              }
            | None => Error({field: "removed", reason: "expected an array of id strings"})
            }
          }
        )
      }

      switch (fromVersion, changed, removed, str("to_version"), str("layer"), str("checksum"), str("signature")) {
      | (
          Ok(fromVersion),
          Ok(changed),
          Ok(removed),
          Some(toVersion),
          Some(layer),
          Some(checksum),
          Some(signature),
        ) =>
        Ok({
          DatasetDelta.fromVersion,
          toVersion,
          layer,
          checksum,
          signature,
          changed,
          removed,
        })
      | (Error(e), _, _, _, _, _, _)
      | (_, Error(e), _, _, _, _, _)
      | (_, _, Error(e), _, _, _, _) => Error(e)
      | _ => Error({field: "?", reason: "missing or invalid required field"})
      }
    }
  }
}
