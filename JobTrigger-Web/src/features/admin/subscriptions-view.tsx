import Link from "next/link";

import { Card } from "@/components/layout";
import type {
  AdminPlanFilter,
  AdminPromoCode,
  AdminSubscription,
} from "@/domain/admin-subscription";
import type { AppFailure } from "@/domain/app-failure";
import { failureMessage } from "@/domain/app-failure";
import { planDate } from "@/features/account/plan-section";
import type { SubscriptionSource } from "@/domain/subscription";

import { PlanAdminForms } from "./subscription-forms";

export const PLAN_FILTERS: readonly { id: AdminPlanFilter; label: string }[] = [
  { id: "all", label: "All accounts" },
  { id: "pro", label: "Pro" },
  { id: "free", label: "Free" },
];

const sourceLabels: Record<SubscriptionSource, string> = {
  appStore: "App Store",
  playStore: "Google Play",
  web: "Website (card)",
  promo: "Promotion",
  admin: "Owner grant",
  student: "Student",
};

const NOTICES: Record<string, string> = {
  granted: "Pro granted. The account sees it on its next request.",
  revoked: "Grant revoked. A paid store or web plan, if any, is untouched.",
};

/**
 * US-PROMO-05: one code's numbers in words. A checkout discount has no local
 * count — Paddle counts its own redemptions on the discount itself.
 */
export function promoCodeLine(code: AdminPromoCode): string {
  const parts: string[] = [];
  if (code.kind === "checkout") {
    parts.push("money off the website checkout (Paddle counts its redemptions)");
  } else {
    parts.push(`Pro for ${code.days} ${code.days === 1 ? "day" : "days"}`);
    const used = `${code.redemptions ?? 0} redeemed`;
    parts.push(
      code.maxRedemptions === null
        ? used
        : `${used} of ${code.maxRedemptions}, ${code.remaining ?? 0} left`,
    );
  }
  if (code.expired) parts.push("past its last day");
  else if (code.expiresAt) parts.push(`usable until ${planDate(code.expiresAt)}`);
  return parts.join(" · ");
}

/** "Pro until March 3, 2027", or where it renews. */
function planLine(item: AdminSubscription): string {
  const date = planDate(item.periodEnd);
  if (item.plan === "free") return "Free";
  if (!date) return "Pro, with no end date";
  return item.willRenew ? `Pro, renews ${date}` : `Pro until ${date}`;
}

/** /admin/subscriptions: every account's plan, and the tester grant controls. */
export function SubscriptionsView({
  items,
  codes = [],
  failure,
  plan,
  q,
  notice,
}: {
  items: AdminSubscription[];
  /** US-PROMO-05: every code configured, with its usage. */
  codes?: AdminPromoCode[];
  failure: AppFailure | null;
  plan: AdminPlanFilter;
  q: string;
  notice?: string;
}) {
  return (
    <>
      <header className="flex flex-col gap-2">
        <h1 className="text-[1.625rem] font-extrabold tracking-[-0.02em]">Subscriptions</h1>
        <p className="text-sm text-muted">
          Every account starts on Free. Grant Pro here to a tester for a bounded window, or with no
          end for the owner. Store and website subscriptions are the customer&apos;s and are never
          changed from here.
        </p>
      </header>
      {notice && NOTICES[notice] && (
        <p
          role="status"
          className="rounded-control bg-success-bg px-3.5 py-3 text-sm font-semibold text-success-fg"
        >
          {NOTICES[notice]}
        </p>
      )}
      {codes.length > 0 && (
        <Card role="region" aria-labelledby="promo-codes-title" className="flex flex-col gap-3 p-5">
          <h2 id="promo-codes-title" className="text-xl font-extrabold">
            Promo codes
          </h2>
          <p className="text-sm text-muted">
            Every code in the deployment&apos;s promotion list, and how much of each is used. A code
            removed with its account frees a slot again.
          </p>
          <ul className="flex flex-col gap-2 text-sm">
            {codes.map((code) => (
              <li key={code.code} className="flex flex-wrap items-baseline gap-x-2 gap-y-1">
                <span className="font-mono font-semibold">{code.code}</span>
                <span className="text-muted">{promoCodeLine(code)}</span>
              </li>
            ))}
          </ul>
        </Card>
      )}
      <nav aria-label="Plan" className="flex flex-wrap gap-2">
        {PLAN_FILTERS.map((filter) => (
          <Link
            key={filter.id}
            href={`/admin/subscriptions?plan=${filter.id}${q ? `&q=${encodeURIComponent(q)}` : ""}`}
            aria-current={filter.id === plan ? "page" : undefined}
            className={`rounded-full border px-3.5 py-1.5 text-sm font-semibold no-underline ${
              filter.id === plan ? "border-accent bg-accent text-on-accent" : "border-line-strong"
            }`}
          >
            {filter.label}
          </Link>
        ))}
      </nav>
      <form
        action="/admin/subscriptions"
        method="get"
        role="search"
        className="flex flex-wrap gap-2"
      >
        <input type="hidden" name="plan" value={plan} />
        <label htmlFor="subscription-search" className="sr-only">
          Search by exact account email
        </label>
        <input
          id="subscription-search"
          type="search"
          name="q"
          defaultValue={q}
          placeholder="Exact account email"
          className="h-11 min-w-0 flex-[1_1_260px] rounded-control border border-line-strong bg-card px-3.5"
        />
        <button
          type="submit"
          className="h-11 rounded-control border border-line-strong bg-card px-4 text-sm font-semibold"
        >
          Search
        </button>
      </form>
      {failure ? (
        <p role="alert" className="text-failed-fg">
          {failureMessage(failure)}
        </p>
      ) : items.length === 0 ? (
        <p>No accounts here.</p>
      ) : (
        <ul className="flex flex-col gap-3">
          {items.map((item) => (
            <li key={item.userId}>
              <Card className="flex flex-col gap-4 p-5">
                <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1">
                  <span className="min-w-0 truncate font-mono text-sm">{item.email}</span>
                  <span className="text-sm font-semibold">{planLine(item)}</span>
                </div>
                <p className="text-sm text-muted">
                  {item.source ? sourceLabels[item.source] : "No active source"}
                  {item.sources.grant && (
                    <>
                      {" · "}
                      Test grant: {planDate(item.sources.grant.periodEnd) ?? "no end date"}
                    </>
                  )}
                  {item.sources.store && " · Store subscription (manage there)"}
                  {item.sources.web && " · Website subscription (manage there)"}
                  {item.sources.student && " · Student year"}
                  {/* US-PROMO-01: a redeemed code, and until when. */}
                  {item.sources.promo && (
                    <>
                      {" · Promo code"}
                      {item.sources.promo.productId ? ` ${item.sources.promo.productId}` : ""}
                      {item.sources.promo.periodEnd
                        ? ` until ${planDate(item.sources.promo.periodEnd)}`
                        : ""}
                    </>
                  )}
                </p>
                <PlanAdminForms userId={item.userId} />
              </Card>
            </li>
          ))}
        </ul>
      )}
    </>
  );
}
