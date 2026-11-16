import Link from "next/link";

import type { PaddleConfig } from "@/billing/paddle-config";
import { Card } from "@/components/layout";
import type { Subscription } from "@/domain/subscription";
import { manageInstructions, planSummary } from "@/features/account/plan-section";

import { routes } from "../marketing/site-links";

import { billingMode } from "./billing-mode";
import { ManageButton, UpgradeButtons } from "./billing-actions";

/**
 * Billing (P20-83): upgrade with Paddle, or manage a web subscription in
 * Paddle's portal. Paddle is the seller here, and the page says so before the
 * checkout opens. Store subscriptions are only explained, never sold twice.
 */
export function BillingView({
  subscription,
  paddle,
}: {
  subscription: Subscription | null;
  paddle: PaddleConfig | null;
}) {
  const mode = billingMode(subscription, paddle);

  return (
    <>
      <p>
        <Link href={routes.account} className="text-sm">
          ← Account
        </Link>
      </p>
      <Card
        role="region"
        aria-labelledby="billing-title"
        className="flex max-w-2xl flex-col gap-4 p-6"
      >
        <h1 id="billing-title" className="text-[1.625rem] font-extrabold tracking-[-0.02em]">
          Billing
        </h1>

        {subscription && mode !== "unavailable" && <p>{planSummary(subscription)}</p>}

        {mode === "unavailable" && (
          <p>
            Buying on the website isn&apos;t available right now. Pro is bought in the JobTrigger
            app, through the App Store or Google Play.
          </p>
        )}

        {mode === "upgrade" && paddle && (
          <>
            <p className="text-fg-secondary">
              Pro adds every tool, as many servers as you need, and the extras. See{" "}
              <Link href={routes.pricing}>what&apos;s included</Link>.
            </p>
            <UpgradeButtons clientToken={paddle.clientToken} environment={paddle.environment} />
            <p className="text-sm text-muted">
              The checkout opens on this page. <strong className="text-fg">Paddle</strong> is the
              seller: it takes the payment, handles tax and sends the receipt. The subscription
              renews until you cancel it. See the <Link href={routes.terms}>terms</Link> and{" "}
              <Link href={routes.privacy}>privacy policy</Link>.
            </p>
          </>
        )}

        {mode === "manage" && (
          <>
            <p className="text-fg-secondary">
              Change your card, see invoices or cancel in Paddle&apos;s customer portal.
            </p>
            <ManageButton />
          </>
        )}

        {mode === "store" && subscription && (
          <p className="text-fg-secondary">
            This subscription is managed by the store you bought it in.{" "}
            {manageInstructions(subscription)}
          </p>
        )}

        {mode === "other" && <p className="text-fg-secondary">There is nothing to manage here.</p>}
      </Card>
    </>
  );
}
