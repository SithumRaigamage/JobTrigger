import type { NextConfig } from "next";

import { staticSecurityHeaders } from "./src/security-headers";

const nextConfig: NextConfig = {
  // No cacheComponents / partialPrefetching: Partial Prerendering can't
  // carry a per-request CSP nonce, so the strict CSP (WEB-B2) needs every
  // page rendered per request. Measured 2026-10-26; see
  // docs/web-architecture.md "Security headers".
  poweredByHeader: false,
  // A self-contained server for the Docker image only (P15-23): the
  // Dockerfile sets NEXT_STANDALONE=1. `next start` and Vercel use the
  // regular output, and `next start` refuses to serve a standalone build.
  ...(process.env.NEXT_STANDALONE === "1" ? { output: "standalone" as const } : {}),
  turbopack: {
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
