/*
 * Details the owner fills in before launch (UI-UX/Web/README.md
 * "Placeholders to fill before launch"). Null renders as the bracketed
 * placeholder text, never as a dead link or an invented value.
 * launch-readiness.test.ts lists whatever is still missing.
 */

export const siteDetails = {
  companyName: null as string | null,
  securityEmail: null as string | null,
  privacyEmail: null as string | null,
  /** Working days to reply to a security report. */
  securityReplyDays: null as number | null,
  /** How long backups keep deleted data, e.g. "35 days". */
  backupRetention: null as string | null,
  /** "Last updated" date on the legal pages, e.g. "1 December 2026". */
  legalLastUpdated: null as string | null,
};

export type SiteDetail = keyof typeof siteDetails;

const placeholders: Record<SiteDetail, string> = {
  companyName: "[COMPANY NAME]",
  securityEmail: "[SECURITY EMAIL]",
  privacyEmail: "[PRIVACY EMAIL]",
  securityReplyDays: "[N]",
  backupRetention: "[RETENTION PERIOD FOR BACKUPS]",
  legalLastUpdated: "[DATE]",
};

/** The value as text, or its bracketed placeholder while unset. */
export function detail(key: SiteDetail): string {
  const value = siteDetails[key];
  return value === null ? placeholders[key] : String(value);
}

/** Keys still unset. */
export function missingDetails(): SiteDetail[] {
  return (Object.keys(siteDetails) as SiteDetail[]).filter((key) => siteDetails[key] === null);
}
