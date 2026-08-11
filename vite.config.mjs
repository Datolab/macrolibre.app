import { defineConfig } from "vite";
import { VitePWA } from "vite-plugin-pwa";
import basicSsl from "@vitejs/plugin-basic-ssl";

// App build/dev config. Vite bundles the ReScript-compiled `*.res.mjs`.
// (Vitest reads vitest.config.mjs, which takes priority for tests.)
export default defineConfig(({ command }) => ({
  // basicSsl + host: true let `npm run dev` be reached over HTTPS from a
  // phone on the same LAN — getUserMedia (the barcode scanner) requires a
  // secure context, which plain http://<lan-ip> doesn't satisfy.
  server: {
    host: true,
  },
  plugins: [
    command === "serve" && basicSsl(),
    VitePWA({
      registerType: "autoUpdate",
      manifest: {
        name: "MacroLibre",
        short_name: "MacroLibre",
        description: "Local-first macro & nutrition tracker. Works offline, no account.",
        theme_color: "#0f172a",
        background_color: "#0f172a",
        display: "standalone",
        start_url: "/",
        icons: [
          {
            src: "/icon.svg",
            sizes: "any",
            type: "image/svg+xml",
            purpose: "any maskable",
          },
        ],
      },
    }),
  ],
}));
