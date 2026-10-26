import { routes } from "./site-links";

/** Every public, indexable page: the sitemap lists exactly these (US-WEB-07). */
export const publicPaths = [
  routes.home,
  routes.features,
  routes.integrations,
  routes.security,
  routes.changelog,
  routes.support,
  routes.privacy,
  routes.terms,
] as const;
