import Link from "next/link";

import { Card } from "@/components/layout";
import { getRelease } from "@/content/release";
import type { Subscription } from "@/domain/subscription";

/*
 * Plan, on the account page (US-SUB-08, P20-32). Display only: no buy
 * button, no link to checkout (that is Phase 21 and the store rules). Shown
 * only when the backend has billing on; with billing off everyone has every
 * feature and a plan section would only confuse.
 */

const sourceLabel = {
  appStore: "the App Store",
  playStore: "Google Play",
  web: "the JobTrigger website",
  promo: "a promotion",
  admin: "JobTrigger",
  student: "the student plan",
} as const;

const dateFormat = new Intl.DateTimeFormat("en", { dateStyle: "long", timeZone: "UTC" });

/** "March 3, 2027", or null when there is no usable date. */
export function planDate(iso: string | null): string | null {
  if (!iso) return null;
  const date = new Date(iso);
  return Number.isNaN(date.getTime()) ? null : dateFormat.format(date);
}

/** One sentence on where the plan stands. */
export function planSummary(subscription: Subscription): string {
  const end = planDate(subscription.periodEnd);
  const from = subscription.source ? ` through ${sourceLabel[subscription.source]}` : "";
  if (subscription.plan === "free") {
    return subscription.state === "expired" || subscription.state === "cancelled"
      ? "Your Pro plan has ended. You're on the Free plan."
      : "You're on the Free plan.";
  }
  switch (subscription.state) {
    case "trialing":
      return `You're on Pro${from}, in your free trial${end ? ` until ${end}` : ""}.`;
    case "grace":
    case "billingIssue":
      return `You're on Pro${from}, but the last payment didn't go through${end ? `. Pro continues until ${end} unless it is fixed` : ""}.`;
    case "cancelled":
      return `You're on Pro${from}. It won't renew${end ? " and ends on " + end : ""}.`;
    default:
      return subscription.willRenew && end
        ? `You're on Pro${from}. It renews on ${end}.`
        : `You're on Pro${from}${end ? `. It ends on ${end}` : ""}.`;
  }
}

/** Where to change or cancel it, for the source. */
export function manageInstructions(subscription: Subscription): string | null {
  if (subscription.plan !== "pro") return null;
  switch (subscription.source) {
    case "appStore":
      return "Manage or cancel it in your iPhone's Settings → your name → Subscriptions.";
    case "playStore":
      return "Manage or cancel it in the Google Play app → Payments & subscriptions → Subscriptions.";
    case "web":
      return "Manage or cancel it from the JobTrigger app.";
    default:
      return null;
  }
}

/**
 * US-SUB-07: deleting the account doesn't cancel a store subscription, so a
 * paid one is named before the user confirms. Null when nothing keeps billing.
 */
export function deleteNotice(subscription: Subscription): string | null {
  if (subscription.plan !== "pro") return null;
  switch (subscription.source) {
    case "appStore":
      return "Deleting your account does not cancel your App Store subscription. Cancel it in your iPhone's Settings → Subscriptions first, or you will keep being charged.";
    case "playStore":
      return "Deleting your account does not cancel your Google Play subscription. Cancel it in the Google Play app → Subscriptions first, or you will keep being charged.";
    case "web":
      return "Deleting your account does not cancel your subscription. Cancel it from the JobTrigger app first, or you will keep being charged.";
    default:
      return null;
  }
}

/** Pro's tools line; it can't say "together" while only one tool is released. */
function toolsLine(multiTool: boolean): string {
  if (!multiTool) return "One tool at a time";
  return getRelease().released.length > 1 ? "All tools together" : "More tools as they release";
}

function limitText(value: number | null, unit: string): string {
  return value === null ? `Unlimited ${unit}` : `${value} ${unit}`;
}

/** The plan card. */
export function PlanSection({
  subscription,
  billingHref = null,
}: {
  subscription: Subscription;
  /** The billing page, when web checkout is set up (P20-83); else null. */
  billingHref?: string | null;
}) {
  const instructions = manageInstructions(subscription);
  const { limits, features } = subscription;
  return (
    <Card
      role="region"
      aria-labelledby="plan-title"
      className="flex min-w-0 flex-[1_1_320px] flex-col gap-4 p-6"
    >
      <h2 id="plan-title" className="text-lg font-extrabold">
        Plan
      </h2>
      <p>{planSummary(subscription)}</p>
      <ul className="flex list-disc flex-col gap-1.5 pl-5.5 text-sm text-fg-secondary">
        <li>{limitText(limits.maxCredentialsTotal, "saved servers in total")}</li>
        <li>{limitText(limits.maxPinnedJobs, "pinned jobs")}</li>
        <li>{toolsLine(features.multiTool)}</li>
      </ul>
      {instructions && <p className="text-sm text-muted">{instructions}</p>}
      {subscription.plan === "free" && (
        <p className="text-sm text-muted">Pro is bought in the JobTrigger app.</p>
      )}
      {billingHref && (
        <p className="text-sm">
          <Link href={billingHref}>Billing</Link>
        </p>
      )}
    </Card>
  );
}
