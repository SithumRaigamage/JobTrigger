import Link from "next/link";

import type { PaddleConfig } from "@/billing/paddle-config";
import { Card } from "@/components/layout";
import type { Subscription } from "@/domain/subscription";
import type { Team } from "@/domain/team";
import { manageInstructions, planSummary } from "@/features/account/plan-section";

import { routes } from "../marketing/site-links";

import { billingMode } from "./billing-mode";
import { ManageButton, TeamCheckout, UpgradeButtons } from "./billing-actions";
import { PromoCodeForm } from "./promo-code-form";

/**
 * Billing (P20-83): upgrade with Paddle, or manage a web subscription in
 * Paddle's portal. Paddle is the seller here, and the page says so before the
 * checkout opens. Store subscriptions are only explained, never sold twice.
 */
export function BillingView({
  subscription,
  paddle,
  team = null,
}: {
  subscription: Subscription | null;
  paddle: PaddleConfig | null;
  /** US-SUB-11: the owner's team, when the team plan is on. */
  team?: Team | null;
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

        {/* US-PROMO-01: where the current plan came from, in words. */}
        {subscription?.plan === "pro" && subscription.source === "promo" && (
          <p className="text-sm text-muted">Redeemed with a promo code.</p>
        )}

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
      {/* US-PROMO-01: only while Free, and only when the backend has codes. */}
      {subscription?.plan === "free" && subscription.promoAvailable && <PromoCodeForm />}
      {team && team.role === "owner" && <TeamBilling team={team} paddle={paddle} />}
    </>
  );
}

/** US-SUB-11 AC13: the team's seats, bought or changed here. */
function TeamBilling({ team, paddle }: { team: Team; paddle: PaddleConfig | null }) {
  const subscribed = team.active && team.billing.willRenew;
  return (
    <Card
      role="region"
      aria-labelledby="team-billing-title"
      className="flex max-w-2xl flex-col gap-4 p-6"
    >
      <h2 id="team-billing-title" className="text-xl font-extrabold">
        Team: {team.name}
      </h2>
      {subscribed ? (
        <p className="text-fg-secondary" data-testid="team-billing-subscribed">
          Your team has {team.seats} seats. Change them on the{" "}
          <Link href="/account/team">team page</Link>; Paddle adjusts the next invoice.
        </p>
      ) : paddle ? (
        <>
          <p className="text-fg-secondary">
            Everyone in the team gets Pro. {team.seatsUsed} of your seats are in use, so you need at
            least {Math.max(team.prices.minSeats, team.seatsUsed)}.
          </p>
          <TeamCheckout
            clientToken={paddle.clientToken}
            environment={paddle.environment}
            prices={team.prices}
            minSeats={team.seatsUsed}
          />
        </>
      ) : (
        <p>Buying for a team on the website isn&apos;t available right now.</p>
      )}
    </Card>
  );
}
