open Vitest

test("lowercases and collapses whitespace", () => {
  expect(SearchKey.normalize("  Rice   Pudding "))->toBe("rice pudding")
})

test("is idempotent on an already-normal key", () => {
  expect(SearchKey.normalize("black beans"))->toBe("black beans")
})
