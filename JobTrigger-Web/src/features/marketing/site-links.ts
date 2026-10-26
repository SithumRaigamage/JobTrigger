// Public routes, in one place so the header, footer and pages agree.
export const routes = {
  home: "/",
  download: "/#download",
  features: "/features",
  integrations: "/integrations",
  requestTool: "/integrations#request",
  security: "/security",
  changelog: "/changelog",
  support: "/support",
  privacy: "/privacy",
  // The approved footer points Terms at the privacy page; P15-10 settles it.
  terms: "/privacy#terms",
  signIn: "/sign-in",
} as const;

export const mainNav = [
  { href: routes.features, label: "Features" },
  { href: routes.integrations, label: "Integrations" },
  { href: routes.security, label: "Security" },
  { href: routes.changelog, label: "Changelog" },
  { href: routes.support, label: "Support" },
] as const;

/**
 * Store listings. Null until the app is listed (release-checklist.md);
 * a store button only links once `app-stores` is live *and* its URL is
 * set, and store-links.test.ts fails if the status is live while either
 * is still null.
 */
export const storeLinks: { appStore: string | null; googlePlay: string | null } = {
  appStore: null,
  googlePlay: null,
};
