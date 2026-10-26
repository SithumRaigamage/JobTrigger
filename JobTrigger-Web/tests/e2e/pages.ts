// Every public page, with its <title>. Add each new page here: the smoke
// and CSP tests run against all of them.
export const publicPages = [
  { path: "/", title: "JobTrigger" },
  { path: "/features", title: "Features · JobTrigger" },
  { path: "/integrations", title: "Integrations · JobTrigger" },
] as const;
