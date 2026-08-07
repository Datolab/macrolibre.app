// A food record from the bundled open base dataset or a verified lookup.
// Pure domain type — no JS interop (ADR-0002). Values only ever reach here
// through a boundary decoder (ADR-0003).

type provenance =
  | Official
  | DietitianVerified
  | OpenData
  | UserSubmitted

type t = {
  id: string,
  nameEn: string,
  nameEs: option<string>,
  region: option<string>,
  provenance: provenance,
  kcal100g: float,
  protein100g: float,
  carbs100g: float,
  fat100g: float,
}
