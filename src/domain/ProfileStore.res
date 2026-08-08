// Port (ADR-0002): load/save the user profile. Infrastructure provides a value
// of this type (backed by localStorage). Synchronous — the profile is tiny.
type t = {
  load: unit => option<Profile.t>,
  save: Profile.t => unit,
}
