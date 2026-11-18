import "server-only";

import { z } from "zod";

import type {
  AdminPlanFilter,
  AdminSubscription,
  AdminBillingSource,
} from "@/domain/admin-subscription";
import type { Result } from "@/domain/result";

import { callBackend } from "./backend-client";

/*
 * Release 1.0.0: the owner's subscription console (docs/api-reference.md
 * `/api/admin/subscriptions`). The backend checks the super-admin role on
 * every call; anyone else gets its plain 404, shown as a 404 page so the
 * admin area never announces itself.
 */

const state = z
  .enum(["none", "trialing", "active", "grace", "billing_issue", "cancelled", "expired"])
  .catch("none")
  .transform((value) => (value === "billing_issue" ? ("billingIssue" as const) : value));

const sourceNames = {
  app_store: "appStore",
  play_store: "playStore",
  web: "web",
  promo: "promo",
  admin: "admin",
  student: "student",
} as const;

const source = z
  .enum(["app_store", "play_store", "web", "promo", "admin", "student"])
  .nullable()
  .catch(null)
  .transform((value) => (value === null ? null : sourceNames[value]));

const billingSource = z
  .object({
    plan: z.enum(["free", "pro"]).catch("free"),
    status: state,
    source,
    periodEnd: z.string().nullable().catch(null),
    willRenew: z.boolean().catch(false),
  })
  .nullable()
  .catch(null)
  .transform(
    (value): AdminBillingSource | null =>
      value === null
        ? null
        : {
            plan: value.plan,
            state: value.status,
            source: value.source,
            periodEnd: value.periodEnd,
            willRenew: value.willRenew,
          },
  );

const item = z
  .object({
    userId: z.string(),
    email: z.string(),
    plan: z.enum(["free", "pro"]).catch("free"),
    status: state,
    source,
    periodEnd: z.string().nullable().catch(null),
    willRenew: z.boolean().catch(false),
    sources: z
      .object({
        store: billingSource,
        web: billingSource,
        grant: billingSource,
        student: billingSource,
      })
      .catch({ store: null, web: null, grant: null, student: null }),
    createdAt: z.string().nullable().catch(null),
  })
  .transform(
    (value): AdminSubscription => ({
      userId: value.userId,
      email: value.email,
      plan: value.plan,
      state: value.status,
      source: value.source,
      periodEnd: value.periodEnd,
      willRenew: value.willRenew,
      sources: value.sources,
      createdAt: value.createdAt,
    }),
  );

const list = z.object({ items: z.array(item) });

export async function listAdminSubscriptions(
  accessToken: string,
  { plan, q }: { plan: AdminPlanFilter; q: string },
): Promise<Result<AdminSubscription[]>> {
  const query = new URLSearchParams({ plan });
  if (q) query.set("q", q);
  const result = await callBackend(
    { path: `/api/admin/subscriptions?${query.toString()}`, accessToken },
    list,
  );
  return result.ok ? { ok: true, value: result.value.items } : result;
}

const OBJECT_ID = /^[a-f0-9]{24}$/i;

/** Ids are built into a path, so only the backend's id shape is allowed. */
export const isAdminSubscriptionId = (value: string): boolean => OBJECT_ID.test(value);

/** Grant Pro to a tester: [days] null means no end date. */
export function grantAdminPlan(
  accessToken: string,
  userId: string,
  days: number | null,
): Promise<Result<AdminSubscription>> {
  return callBackend(
    {
      method: "POST",
      path: `/api/admin/subscriptions/${userId}/grant`,
      body: days === null ? {} : { days },
      accessToken,
      explain: true,
    },
    item,
  );
}

/** Take the test grant away. A paid store or web plan is never touched. */
export function revokeAdminPlan(
  accessToken: string,
  userId: string,
): Promise<Result<AdminSubscription>> {
  return callBackend(
    {
      method: "POST",
      path: `/api/admin/subscriptions/${userId}/revoke`,
      accessToken,
      explain: true,
    },
    item,
  );
}
