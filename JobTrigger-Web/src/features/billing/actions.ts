"use server";

import { z } from "zod";

import { failureMessage } from "@/domain/app-failure";
import { authed } from "@/server/authed";
import { createCheckout, createPortalLink } from "@/server/billing-api";
import { requireSession } from "@/server/guard";
import { redeemPromoCode } from "@/server/subscription-api";

/*
 * The two billing actions (P20-83). Both check the session themselves (the
 * proxy is skipped for prefetches), and both only forward to the backend:
 * the price, the user and the amount are decided there.
 */

export type CheckoutState =
  { error: string } | { transactionId: string; environment: "sandbox" | "production" };

const interval = z.enum(["monthly", "yearly"]);

/** Creates the transaction the browser then opens with Paddle.js. */
export async function startCheckoutAction(chosen: string): Promise<CheckoutState> {
  const session = await requireSession();
  const parsed = interval.safeParse(chosen);
  if (!parsed.success) return { error: "Choose monthly or yearly." };

  const result = await authed(session, (token) => createCheckout(token, parsed.data));
  if (!result.ok) return { error: failureMessage(result.failure) };
  return result.value;
}

export type PromoState = { error: string } | { ok: true };

/**
 * US-PROMO-01: redeems a promo or voucher code. The code is decided on the
 * backend; a refusal comes back as its own sentence to show in the form.
 */
export async function redeemPromoCodeAction(
  _previous: PromoState | null,
  form: FormData,
): Promise<PromoState> {
  const session = await requireSession();
  const code = String(form.get("code") ?? "").trim();
  if (!code) return { error: "Enter a code." };
  if (code.length > 64) return { error: "That code is too long." };

  const result = await authed(session, (token) => redeemPromoCode(token, code));
  if (!result.ok) return { error: failureMessage(result.failure) };
  return { ok: true };
}

export type PortalState = { error: string } | { url: string };

/** A one-time link to Paddle's customer portal. */
export async function openPortalAction(): Promise<PortalState> {
  const session = await requireSession();
  const result = await authed(session, (token) => createPortalLink(token));
  if (!result.ok) return { error: failureMessage(result.failure) };
  return { url: result.value };
}
