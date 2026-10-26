import type { MetadataRoute } from "next";

import { publicPaths } from "@/features/marketing/public-pages";
import { getSiteUrl } from "@/server/config";

export default function sitemap(): MetadataRoute.Sitemap {
  const siteUrl = getSiteUrl();
  return publicPaths.map((path) => ({ url: `${siteUrl}${path === "/" ? "" : path}` }));
}
