import "server-only";

import { z } from "zod";

import { ok, type Result } from "@/domain/result";
import type { Subscription } from "@/domain/subscription";

import { callBackend } from "./backend-client";

/*
 * GET /api/subscription (docs/api-reference.md, P20-14): the signed-in
 * user's plan, for the account page (US-SUB-08). Read-only: the website
 * has no purchase or cancel call in this phase. Parsed leniently where the
 * backend may add values (an unknown status or source reads as none/null)
 * so a newer backend never breaks the account page.
 */

// The wire values are snake_case (the app's subscription_dto.dart maps the
// same strings); the domain type uses camelCase.
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
} as const;

const source = z
  .enum(["app_store", "play_store", "web", "promo", "admin"])
  .nullable()
  .catch(null)
  .transform((value) => (value === null ? null : sourceNames[value]));

const limit = z.number().int().nullable().default(null);

const dto = z.object({
  plan: z.enum(["free", "pro"]).catch("free"),
  billingEnabled: z.boolean(),
  status: state,
  source: source.optional().default(null),
  periodEnd: z.string().nullable().optional().default(null),
  willRenew: z.boolean().optional().default(false),
  manageOnWeb: z.boolean().optional().default(false),
  limits: z.object({
    maxCredentialsTotal: limit,
    maxCredentialsPerTool: limit,
    maxPinnedJobs: limit,
  }),
  features: z.object({
    multiTool: z.boolean().default(false),
    backgroundWatch: z.boolean().default(false),
    homeWidget: z.boolean().default(false),
    insights: z.boolean().default(false),
  }),
});

export async function getSubscription(accessToken: string): Promise<Result<Subscription>> {
  const result = await callBackend({ path: "/api/subscription", accessToken }, dto);
  if (!result.ok) return result;
  const { status, ...rest } = result.value;
  return ok({ ...rest, state: status });
}
