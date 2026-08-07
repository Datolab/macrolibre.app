import { defineConfig } from "vitest/config";

// Tests are written in ReScript and compiled in-source to `*_test.res.mjs`.
export default defineConfig({
  test: {
    globals: true,
    include: ["src/**/*_test.res.mjs", "test/**/*_test.res.mjs"],
  },
});
