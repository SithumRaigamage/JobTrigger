"use client";

import Script from "next/script";
import { useState, useTransition } from "react";

import { Notice } from "@/components/form";
import { PADDLE_SCRIPT_URL, type PaddleEnvironment } from "@/billing/paddle-config";

import { teamTotal, usd, type TeamPeriod, type TeamPrices } from "@/domain/team";
import { startTeamCheckoutAction } from "@/features/team/actions";

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

/**
 * Upgrade: monthly or yearly, then Paddle's checkout overlay. US-PROMO-04: an
 * optional discount code is sent with the interval and applied by the backend
 * when it creates the Paddle transaction, so the price shown is the price
 * charged.
 */
export function UpgradeButtons({
  clientToken,
  environment,
}: {
  clientToken: string;
  environment: PaddleEnvironment;
}) {
  const [ready, setReady] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [code, setCode] = useState("");
  const [pending, startTransition] = useTransition();

  const start = (interval: "monthly" | "yearly") =>
    startTransition(async () => {
      setError(null);
      const paddle = window.Paddle;
      if (!paddle) {
        setError(loadError);
        return;
      }
      const result = await startCheckoutAction(interval, code.trim() || undefined);
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
      {/* US-PROMO-04: named for what it does, because the billing page also
          has the "Redeem a code for free Pro time" form below. */}
      <div className="flex w-full max-w-sm flex-col gap-2">
        <label htmlFor="discount-code" className="text-[0.8125rem] font-semibold text-fg-secondary">
          Discount code (money off this purchase)
        </label>
        <input
          id="discount-code"
          aria-describedby="discount-code-hint"
          type="text"
          value={code}
          onChange={(event) => setCode(event.target.value)}
          maxLength={64}
          autoComplete="off"
          spellCheck={false}
          placeholder="SAVE20"
          className="h-11 rounded-[12px] border border-line-strong bg-card px-3 font-mono text-base text-fg"
        />
        <p id="discount-code-hint" className="text-xs text-muted">
          Takes a percentage off this checkout only. It does not add Pro time — a code for free Pro
          days is redeemed in the section below, not here.
        </p>
      </div>
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

/**
 * US-SUB-11 AC13: seats and period, the total worked out, then Paddle's
 * checkout for the team. Rendered only on this page (the CSP exception).
 */
export function TeamCheckout({
  clientToken,
  environment,
  prices,
  minSeats,
}: {
  clientToken: string;
  environment: PaddleEnvironment;
  prices: TeamPrices;
  minSeats: number;
}) {
  const [ready, setReady] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [seats, setSeats] = useState(Math.max(prices.minSeats, minSeats));
  const [period, setPeriod] = useState<TeamPeriod>("yearly");
  const [pending, startTransition] = useTransition();
  const valid =
    Number.isInteger(seats) &&
    seats >= Math.max(prices.minSeats, minSeats) &&
    seats <= prices.maxSeats;

  const start = () =>
    startTransition(async () => {
      setError(null);
      const paddle = window.Paddle;
      if (!paddle) {
        setError(loadError);
        return;
      }
      const result = await startTeamCheckoutAction(period, seats);
      if ("error" in result) {
        setError(result.error);
        return;
      }
      paddle.Checkout.open({ transactionId: result.transactionId });
    });

  return (
    <div className="flex flex-col gap-3" data-testid="team-checkout">
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
      <div className="flex flex-wrap items-end gap-4">
        <label className="flex flex-col gap-2 text-[0.8125rem] font-semibold text-fg-secondary">
          Seats
          <input
            type="number"
            min={Math.max(prices.minSeats, minSeats)}
            max={prices.maxSeats}
            value={Number.isNaN(seats) ? "" : seats}
            onChange={(event) => setSeats(Number.parseInt(event.target.value, 10))}
            className="h-11 w-28 rounded-[12px] border border-line-strong bg-card px-3 text-base text-fg"
          />
        </label>
        <fieldset className="flex gap-4">
          <legend className="sr-only">Billing period</legend>
          {(["yearly", "monthly"] as const).map((value) => (
            <label key={value} className="flex items-center gap-2 text-[0.9375rem]">
              <input
                type="radio"
                name="team-period"
                value={value}
                checked={period === value}
                onChange={() => setPeriod(value)}
              />
              {value === "yearly" ? "Yearly" : "Monthly"}
            </label>
          ))}
        </fieldset>
      </div>
      <p data-testid="team-total" className="text-fg-secondary">
        {valid
          ? `${seats} seats × ${usd(prices[period])} = ${usd(teamTotal(prices, seats, period))} per ${period === "yearly" ? "year" : "month"}`
          : `Choose ${Math.max(prices.minSeats, minSeats)} to ${prices.maxSeats} seats.`}
      </p>
      {error && <Notice tone="error">{error}</Notice>}
      <button
        type="button"
        className={`${primary} self-start`}
        disabled={!ready || pending || !valid}
        onClick={start}
      >
        Buy Pro for the team
      </button>
    </div>
  );
}
