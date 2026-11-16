import "server-only";

import { z } from "zod";

import type { Result } from "@/domain/result";
import { fail, ok } from "@/domain/result";

import { callBackend } from "./backend-client";

/*
 * Web checkout through Paddle (P20-83), both calls via the backend, which
 * holds Paddle's API key; the website never sees it. The user id on a
 * checkout is set by the backend from the access token, never by this site.
 */

export type CheckoutInterval = "monthly" | "yearly";

const checkoutDto = z.object({
  transactionId: z.string().min(1),
  environment: z.enum(["sandbox", "production"]),
});

export type Checkout = z.infer<typeof checkoutDto>;

/** Creates a Paddle transaction for the signed-in user. 409 when already Pro. */
export async function createCheckout(
  accessToken: string,
  interval: CheckoutInterval,
): Promise<Result<Checkout>> {
  return callBackend(
    { method: "POST", path: "/api/billing/paddle/checkout", body: { interval }, accessToken },
    checkoutDto,
  );
}

const portalDto = z.object({ url: z.url() });

/**
 * A one-time link to Paddle's customer portal (card, invoices, cancel). Only
 * ever an https URL on paddle.com: anything else is refused, so a bad
 * response can't send a customer somewhere else.
 */
export async function createPortalLink(accessToken: string): Promise<Result<string>> {
  const result = await callBackend(
    { method: "POST", path: "/api/billing/paddle/portal", accessToken },
    portalDto,
  );
  if (!result.ok) return result;
  return isPaddleUrl(result.value.url) ? ok(result.value.url) : fail({ kind: "unexpected" });
}

export function isPaddleUrl(value: string): boolean {
  try {
    const url = new URL(value);
    return url.protocol === "https:" && /(^|\.)paddle\.com$/.test(url.hostname);
  } catch {
    return false;
  }
}
