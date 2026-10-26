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
    case "unexpected":
      return "The server sent a response the app didn't understand. Check that the server URL is correct — not a login page or proxy.";
    case "unknown":
      return "Something unexpected happened. Please try again.";
  }
}
