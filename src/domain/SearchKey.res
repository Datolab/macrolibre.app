// Normalizes a food name into a search key: lowercased, whitespace-collapsed.
// The client indexes this key for <100 ms local search (ADR-0006). Accent-
// folding (café ~ cafe) is a future improvement noted in ADR-0006.
let normalize = (name: string): string =>
  name->String.replaceRegExp(%re("/\s+/g"), " ")->String.trim->String.toLowerCase
