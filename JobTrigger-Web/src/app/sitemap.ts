import type { MetadataRoute } from "next";

import { publicPaths } from "@/features/marketing/public-pages";
import { getSiteUrl } from "@/server/config";

// Per request: SITE_URL is runtime config, and a build-time render would
// bake in whatever (or nothing) the build machine had (found in P15-22).
export const dynamic = "force-dynamic";

export default function sitemap(): MetadataRoute.Sitemap {
  const siteUrl = getSiteUrl();
  return publicPaths.map((path) => ({ url: `${siteUrl}${path === "/" ? "" : path}` }));
}
