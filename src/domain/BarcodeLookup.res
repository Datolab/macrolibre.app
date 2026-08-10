// Port (ADR-0002): resolve a scanned barcode to a food. Infrastructure provides
// a value of this type (an Open Food Facts online lookup). `None` = not found.
type t = {lookup: string => promise<option<Food.t>>}
