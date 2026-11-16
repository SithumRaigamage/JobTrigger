/*
 * Every way a backend call can fail, mirroring the backend-relevant part of
 * the app's sealed AppFailure (JobTrigger-Frontend/lib/core/error/
 * app_failure.dart) with the same copy, so a problem reads the same on both
 * (docs/web-architecture.md §5 "Errors"). Components render
 * failureMessage(); they never write their own error strings or look at
 * status codes.
 */

export type AppFailure =
  | { kind: "network" }
  | { kind: "auth" }
  | { kind: "notFound" }
  /** A backend 400 with its own user-facing message (AUD-06/AUD-65). */
  | { kind: "rejected"; message: string }
  | { kind: "server"; status: number; requestId?: string }
  /**
   * P20-31: a backend 403 `PLAN_LIMIT` — the plan doesn't allow this. [limit]
   * is the backend's own value (`maxCredentialsTotal`, `locked`, ...). The
   * app shows an Upgrade action; the website says where to upgrade.
   */
  | { kind: "planLimit"; limit: string }
  /** 403 TOOL_NOT_AVAILABLE — this release doesn't ship the tool (release/tools.json). */
  | { kind: "toolUnavailable" }
  /** P20-83: 409 ALREADY_SUBSCRIBED — Pro from any source; nothing to buy. */
  | { kind: "alreadySubscribed" }
  /** P20-83: 503 — billing is off or web checkout isn't set up. */
  | { kind: "billingUnavailable" }
  /** The response didn't match the expected shape. */
  | { kind: "unexpected" }
  | { kind: "unknown" };

export function failureMessage(failure: AppFailure): string {
  switch (failure.kind) {
    case "network":
      return "Can't reach the server. Check your connection and try again.";
    case "auth":
      return "Your credentials were rejected. Please check them and try again.";
    case "notFound":
      return "That couldn't be found — it may have been removed.";
    case "rejected":
      return failure.message;
    case "server":
      // The backend throttles login and signup (AUD-05).
      if (failure.status === 429)
        return "Too many attempts. Please wait a few minutes and try again.";
      return failure.requestId
        ? `Something went wrong on the server (HTTP ${failure.status}). Reference: ${failure.requestId}`
        : `Something went wrong on the server (HTTP ${failure.status}).`;
    case "toolUnavailable":
      return "This tool isn't available yet in this release of JobTrigger.";
    case "alreadySubscribed":
      return "You already have Pro. There is nothing more to buy.";
    case "billingUnavailable":
      return "Buying on the website isn't available right now. Pro can be bought in the JobTrigger app.";
    case "planLimit":
      // Same meaning as the app's PlanLimitFailure. No link: the website
      // never sells (the App Store and Play rules, Phase 21).
      return failure.limit === "locked"
        ? "This server is locked on your plan. Upgrade in the JobTrigger app to use it."
        : "Your plan's limit has been reached. Upgrade in the JobTrigger app to add more.";
    case "unexpected":
      return "The server sent a response the app didn't understand. Check that the server URL is correct — not a login page or proxy.";
    case "unknown":
      return "Something unexpected happened. Please try again.";
  }
}
