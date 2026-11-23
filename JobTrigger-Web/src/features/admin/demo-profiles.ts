/*
 * Phase 32 (WEB-DEMO): fictional study profiles for the five local demo
 * student applications. This is website-only display data, keyed by the
 * fixed `demo-*` account emails from scripts/seed-demo-students.js. It is not
 * part of AdminStudent, the API or the database, and every idea below is a
 * suggestion for a future improvement — none of it is shipped.
 */

export type DemoProfile = {
  name: string;
  course: string;
  university: string;
  ideas: readonly string[];
};

export const DEMO_PROFILES: Readonly<Record<string, DemoProfile>> = {
  "demo-nimali@jobtrigger.app": {
    name: "Nimali Silva",
    course: "BSc Computer Science, Year 3",
    university: "University of Moratuwa",
    ideas: [
      "Show the verified-on date in the queue so a reviewer can see the code step passed.",
      "Preview the 365-day end date before approving.",
      "Prefill course and year from the university domain — still a manual decision, no third-party check.",
    ],
  },
  "demo-kasun@jobtrigger.app": {
    name: "Kasun Perera",
    course: "Diploma in DevOps, Year 2",
    university: "SLIIT",
    ideas: [
      "Let the reviewer zoom and rotate the student ID before deciding.",
      "Offer “request a clearer photo” as a one-click rejection reason.",
      "Later: read the name from the ID with OCR, but keep a person confirming it.",
    ],
  },
  "demo-anushka@jobtrigger.app": {
    name: "Anushka Fernando",
    course: "MSc Software Engineering",
    university: "University of Peradeniya",
    ideas: [
      "Show days remaining in the history row.",
      "Surface the 7-day expiry reminder status.",
      "Later: renewal behind the existing flag, which is currently off.",
    ],
  },
  "demo-tharindu@jobtrigger.app": {
    name: "Tharindu Wickramasinghe",
    course: "BSc Information Technology, Year 1",
    university: "University of Colombo School of Computing",
    ideas: [
      "Show this applicant's earlier attempts beside the rejection reason.",
      "Resend the reason with a clearer-photo tip.",
      "Later: let them upload a new ID without restarting the whole verification flow.",
    ],
  },
  "demo-maya@jobtrigger.app": {
    name: "Maya Chandrasekaran",
    course: "BEng Electrical Engineering, Year 4",
    university: "University of Ruhuna",
    ideas: [
      "Show the exact end date in the Ended filter.",
      "Later: a win-back email when a student's year has ended.",
      "Later: an apply-again link if they are still enrolled.",
    ],
  },
};

/** The fictional profile for one seeded demo account, or null for a real one. */
export function demoProfileFor(accountEmail: string | null): DemoProfile | null {
  return accountEmail ? (DEMO_PROFILES[accountEmail] ?? null) : null;
}
