"use client";

import { useRouter } from "next/navigation";
import { useActionState, useEffect } from "react";

import { Card } from "@/components/layout";

import { redeemPromoCodeAction, type PromoState } from "./actions";

const submit =
  "h-11 rounded-control bg-accent px-5 text-[0.9375rem] font-bold text-on-accent hover:bg-accent-hover disabled:opacity-70";

/**
 * US-PROMO-01: redeem a promo or voucher code, on the billing page.
 *
 * A refused code (used, already Pro, not valid) shows the backend's own
 * sentence and the form stays usable. On success the page is re-read, so the
 * plan above shows Pro with its end date.
 *
 * US-PROMO-04: the page also has a discount field at the checkout; the
 * heading and copy here say this one gives Pro days, not money off.
 */
export function PromoCodeForm() {
  const router = useRouter();
  const [state, formAction, pending] = useActionState<PromoState | null, FormData>(
    redeemPromoCodeAction,
    null,
  );
  const accepted = state !== null && "ok" in state;

  useEffect(() => {
    if (accepted) router.refresh();
  }, [accepted, router]);

  return (
    <Card role="region" aria-labelledby="promo-title" className="flex max-w-2xl flex-col gap-3 p-6">
      <h2 id="promo-title" className="text-xl font-extrabold">
        Redeem a code for free Pro time
      </h2>
      <p className="text-sm text-muted">
        Adds Pro days to your account at no charge. A code that takes money off a purchase is not
        redeemed here — it goes in the discount box at the checkout.
      </p>
      <form action={formAction} className="flex flex-col gap-3">
        <label htmlFor="promo-code" className="text-sm font-semibold">
          Code
        </label>
        <div className="flex flex-wrap gap-2">
          <input
            id="promo-code"
            name="code"
            type="text"
            required
            maxLength={64}
            autoComplete="off"
            spellCheck={false}
            placeholder="LAUNCH30"
            className="h-11 min-w-0 flex-[1_1_240px] rounded-control border border-line-strong bg-card px-3.5 font-mono"
          />
          <button type="submit" disabled={pending} className={submit}>
            {pending ? "Redeeming…" : "Redeem"}
          </button>
        </div>
        {state !== null && "error" in state && (
          <p role="alert" className="text-failed-fg">
            {state.error}
          </p>
        )}
        {accepted && (
          <p role="status" className="text-sm text-fg-secondary">
            Accepted. Your plan is updated above.
          </p>
        )}
      </form>
    </Card>
  );
}
