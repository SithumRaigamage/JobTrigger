import type { NextConfig } from "next";

import { staticSecurityHeaders } from "./src/security-headers";

const nextConfig: NextConfig = {
  // No cacheComponents / partialPrefetching: Partial Prerendering can't
  // carry a per-request CSP nonce, so the strict CSP (WEB-B2) needs every
  // page rendered per request. Measured 2026-10-26; see
  // docs/web-architecture.md "Security headers".
  poweredByHeader: false,
  // The release-1.0 smoke run (playwright.config.ts) builds into its own
  // folder so it can sit next to the all-tools build. Unset: the usual .next.
  ...(process.env.NEXT_DIST_DIR ? { distDir: process.env.NEXT_DIST_DIR } : {}),
  // No dev toolbar: under `next dev` it injects <style> blocks without the
  // CSP nonce, the strict policy blocks them, and it renders as a blank box
  // over the logo. Kept off rather than loosening the dev CSP, so dev and
  // production share one policy (owner decision 2026-10-26).
  devIndicators: false,
  // A self-contained server for the Docker image only (P15-23): the
  // Dockerfile sets NEXT_STANDALONE=1. `next start` and Vercel use the
  // regular output, and `next start` refuses to serve a standalone build.
  ...(process.env.NEXT_STANDALONE === "1" ? { output: "standalone" as const } : {}),
  // Phase 21: a student document (up to 5 MB) is posted to a server action as
  // form data, which Next caps at 1 MB by default.
  experimental: { serverActions: { bodySizeLimit: "8mb" } },
  turbopack: {
    // End-to-end builds only (playwright.config.ts): the specs add GitHub and
    // SonarQube servers, which release 1.0's manifest hides, so they build
    // against an all-tools manifest. A normal build never sets this.
    ...(process.env.E2E_ALL_TOOLS === "1"
      ? { resolveAlias: { "@/content/tools.json": "./tests/e2e/all-tools.json" } }
      : {}),
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
  async headers() {
    return [{ source: "/:path*", headers: staticSecurityHeaders() }];
  },
};

export default nextConfig;
