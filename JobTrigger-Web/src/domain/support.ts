/*
 * Phase 31 (US-SUP-05…07): the support ticket options and checks shared by
 * the signed-in form and the owner console. Plain TS, no Next imports. The
 * wire values are the backend's enums (models/SupportTicket.js); labels are
 * the user-facing copy from the app so both clients read the same.
 */

export const SUPPORT_CATEGORIES = [
  "bug",
  "feature",
  "question",
  "tool_request",
  "account",
  "billing",
  "other",
] as const;
export type SupportCategory = (typeof SUPPORT_CATEGORIES)[number];

export const CATEGORY_LABELS: Record<SupportCategory, string> = {
  bug: "Bug",
  feature: "Feature idea",
  question: "Question",
  tool_request: "Tool request",
  account: "Account & sign-in",
  billing: "Billing & subscription",
  other: "Something else",
};

export const SUPPORT_AREAS = [
  "jenkins",
  "github",
  "sonarqube",
  "website",
  "phone",
  "account",
] as const;
export type SupportArea = (typeof SUPPORT_AREAS)[number];

export const AREA_LABELS: Record<SupportArea, string> = {
  jenkins: "Jenkins",
  github: "GitHub Actions",
  sonarqube: "SonarQube",
  website: "Website",
  phone: "Phone/app",
  account: "Account",
};

export const SUPPORT_IMPACTS = ["blocked", "major", "minor"] as const;
export type SupportImpact = (typeof SUPPORT_IMPACTS)[number];

export const IMPACT_LABELS: Record<SupportImpact, string> = {
  blocked: "Blocked",
  major: "Major",
  minor: "Minor",
};

export const SUPPORT_STATUSES = ["open", "triaged", "closed"] as const;
export type SupportStatus = (typeof SUPPORT_STATUSES)[number];

export const STATUS_LABELS: Record<SupportStatus, string> = {
  open: "Open",
  triaged: "Triaged",
  closed: "Closed",
};

/** Unknown wire values (older tickets) read as themselves, never as a blank. */
export function labelFor<K extends string>(labels: Record<K, string>, wire: string): string {
  return labels[wire as K] ?? wire;
}

export const MAX_SCREENSHOTS = 3;
export const MAX_SCREENSHOT_BYTES = 5 * 1024 * 1024;
/** For the file input's `accept`. */
export const SCREENSHOT_ACCEPT = ".jpg,.jpeg,.png,image/jpeg,image/png";

export type ScreenshotProblem = "empty" | "tooLarge" | "wrongType";

export function screenshotProblemMessage(problem: ScreenshotProblem): string {
  switch (problem) {
    case "empty":
      return "That screenshot is empty. Choose another.";
    case "tooLarge":
      return "Each screenshot must be under 5 MB.";
    case "wrongType":
      return "Screenshots must be JPG or PNG images.";
  }
}

/** The cheap check, from the name and size alone (before reading the file). */
export function checkScreenshotMeta(name: string, size: number): ScreenshotProblem | null {
  if (size <= 0) return "empty";
  if (size > MAX_SCREENSHOT_BYTES) return "tooLarge";
  const dot = name.lastIndexOf(".");
  const extension = dot < 0 ? "" : name.slice(dot + 1).toLowerCase();
  return (["jpg", "jpeg", "png"] as const as readonly string[]).includes(extension)
    ? null
    : "wrongType";
}

const SIGNATURES: readonly (readonly number[])[] = [
  [0xff, 0xd8, 0xff],
  [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
];

/** True when [bytes] start like a JPG or PNG; the name can lie. */
export function looksLikeScreenshot(bytes: Uint8Array): boolean {
  return SIGNATURES.some(
    (signature) =>
      bytes.length > signature.length && signature.every((value, index) => bytes[index] === value),
  );
}

/** One screenshot's metadata in the owner's ticket detail (never bytes). */
export type SupportScreenshotMeta = {
  index: number;
  mime: string;
  size: number;
  hash: string;
  createdAt: string | null;
  deletedAt: string | null;
};

/** A row of the owner's queue, or the whole detail with `screenshots`. */
export type AdminSupportTicket = {
  id: string;
  category: string;
  subject: string;
  message: string;
  areas: string[];
  impact: string;
  screenshotCount: number;
  status: string;
  createdAt: string;
  updatedAt: string;
  replyEmail: string | null;
  userEmail: string | null;
  appVersion: string | null;
  buildNumber: string | null;
  tool: string | null;
  platform: string | null;
  serverHost: string | null;
  /** Detail only; absent from the queue. */
  screenshots?: SupportScreenshotMeta[];
};
