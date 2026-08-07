// Use case (ADR-0002): ingest an open base bundle into local storage.
// Pure orchestration over ports — fetch the text, decode it (per-line boundary
// decoding via BundleDecoder/FoodDecoder, ADR-0003), upsert into the repository.
// No I/O of its own, so it is testable with a fake fetch + fake repository.
type report = {
  ingested: int,
  rejected: int,
}

let run = async (~fetchText: unit => promise<string>, ~repository: FoodRepository.t): report => {
  let text = await fetchText()
  let decoded = BundleDecoder.decodeNdjson(text)
  await repository.upsertMany(decoded.foods)
  {ingested: Array.length(decoded.foods), rejected: decoded.rejected}
}
