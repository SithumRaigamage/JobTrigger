import type { MetadataRoute } from "next";

import { NO_STORE_PATH_PREFIXES } from "@/security-headers";
import { getSiteUrl } from "@/server/config";

// Per request: SITE_URL is runtime config, and a build-time render would
// bake in whatever (or nothing) the build machine had (found in P15-22).
export const dynamic = "force-dynamic";

// Portal pages (the same list that gets no-store) are never crawled
// (US-WEB-07); they also send X-Robots-Tag: noindex.
export default function robots(): MetadataRoute.Robots {
  const siteUrl = getSiteUrl();
  return {
    rules: { userAgent: "*", allow: "/", disallow: [...NO_STORE_PATH_PREFIXES] },
    sitemap: `${siteUrl}/sitemap.xml`,
  };
}
