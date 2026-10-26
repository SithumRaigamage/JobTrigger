// Every public page, with its <title>. Add each new page here: the smoke
// and CSP tests run against all of them.
export const publicPages = [
  { path: "/", title: "JobTrigger" },
  { path: "/features", title: "Features · JobTrigger" },
  { path: "/integrations", title: "Integrations · JobTrigger" },
  { path: "/security", title: "Security · JobTrigger" },
  { path: "/changelog", title: "Changelog · JobTrigger" },
  { path: "/privacy", title: "Privacy policy · JobTrigger" },
  { path: "/terms", title: "Terms of use · JobTrigger" },
  { path: "/support", title: "Support · JobTrigger" },
] as const;
