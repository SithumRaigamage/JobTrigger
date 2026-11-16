"use client";

import Script from "next/script";
import { useState, useTransition } from "react";

import { Notice } from "@/components/form";
import { PADDLE_SCRIPT_URL, type PaddleEnvironment } from "@/billing/paddle-config";

import { openPortalAction, startCheckoutAction } from "./actions";

/*
 * The only client code that touches Paddle. Paddle.js is loaded here, from
 * Paddle's own CDN, and this component is rendered only by the billing page,
 * the one route whose CSP allows it (security-headers.ts).
 */

type PaddleGlobal = {
  Environment: { set(environment: PaddleEnvironment): void };
  Initialize(options: { token: string }): void;
  Checkout: { open(options: { transactionId: string }): void };
};

declare global {
  interface Window {
    Paddle?: PaddleGlobal;
  }
}

const primary =
  "h-12 rounded-full bg-accent px-5 text-[0.9375rem] font-bold text-on-accent hover:bg-accent-hover disabled:opacity-70";
const secondary =
  "h-12 rounded-full border border-line-strong bg-card px-5 text-[0.9375rem] font-semibold text-fg hover:bg-raised disabled:opacity-70";

const loadError = "The checkout couldn't load. Check your connection and try again.";

/** Upgrade: monthly or yearly, then Paddle's checkout overlay. */
export function UpgradeButtons({
  clientToken,
  environment,
}: {
  clientToken: string;
  environment: PaddleEnvironment;
}) {
  const [ready, setReady] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  const start = (interval: "monthly" | "yearly") =>
    startTransition(async () => {
      setError(null);
      const paddle = window.Paddle;
      if (!paddle) {
        setError(loadError);
        return;
      }
      const result = await startCheckoutAction(interval);
      if ("error" in result) {
        setError(result.error);
        return;
      }
      paddle.Checkout.open({ transactionId: result.transactionId });
    });

  return (
    <div className="flex flex-col gap-3">
      <Script
        src={PADDLE_SCRIPT_URL}
        strategy="afterInteractive"
        onReady={() => {
          const paddle = window.Paddle;
          if (!paddle) return;
          paddle.Environment.set(environment);
          paddle.Initialize({ token: clientToken });
          setReady(true);
        }}
        onError={() => setError(loadError)}
      />
      {error && <Notice tone="error">{error}</Notice>}
      <div className="flex flex-wrap gap-3">
        <button
          type="button"
          className={primary}
          disabled={!ready || pending}
          onClick={() => start("yearly")}
        >
          Upgrade, yearly
        </button>
        <button
          type="button"
          className={secondary}
          disabled={!ready || pending}
          onClick={() => start("monthly")}
        >
          Upgrade, monthly
        </button>
      </div>
    </div>
  );
}

/** Manage: one-time link to Paddle's customer portal. */
export function ManageButton() {
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();

  return (
    <div className="flex flex-col gap-3">
      {error && <Notice tone="error">{error}</Notice>}
      <button
        type="button"
        className={`${secondary} self-start`}
        disabled={pending}
        onClick={() =>
          startTransition(async () => {
            setError(null);
            const result = await openPortalAction();
            if ("error" in result) setError(result.error);
            else window.location.assign(result.url);
          })
        }
      >
        Manage subscription
      </button>
    </div>
  );
}
