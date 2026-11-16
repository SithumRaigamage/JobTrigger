import Link from "next/link";

import { Card, Container, Kicker, Section } from "@/components/layout";
import { FeatureAction } from "@/components/feature-action";
import { StatusBadge } from "@/components/status-badge";
import { pricingFor, type Cell } from "@/content/pricing";
import { statusOf } from "@/content/feature-status";
import { getRelease } from "@/content/release";

import { routes } from "../site-links";

function CellText({ cell }: { cell: Cell }) {
  // Never colour or an icon alone: the words say it (US-WEB-22 / a11y).
  if (!cell.included) return <span className="text-muted">Not included</span>;
  return <span>{cell.note ?? "Included"}</span>;
}

/**
 * Pricing (US-SUB-08, P20-33). Renders content/pricing.ts and nothing else.
 * While `subscriptions` isn't live (billing switched off), the Pro action is
 * a disabled "Coming soon" control, as for any other unreleased feature
 * (US-WEB-22); there is no buy button on this site in this phase.
 */
export function PricingView() {
  // Worded for the tools this release ships (release/tools.json).
  const { plans, comparison, promises: pricingPromises } = pricingFor(getRelease());
  // Phase 21: the student offer is only real while Pro is on sale, i.e. billing is on.
  const studentOffer = statusOf("subscriptions") === "live";
  return (
    <main id="content" tabIndex={-1} className="flex-1">
      <Section className="py-16">
        <Container width="medium" className="flex flex-col gap-10">
          <header className="flex flex-col gap-3">
            <Kicker>Pricing</Kicker>
            <h1 className="text-[2.5rem] font-extrabold tracking-[-0.02em]">
              Free to start. Pro for your whole CI estate.
            </h1>
            <p className="max-w-2xl text-lg leading-[1.7] text-fg-secondary">
              One server is free, fully usable. Pro adds every tool, as many servers as you need,
              and the extras for running builds from your phone.
            </p>
          </header>

          <ul className="grid grid-cols-[repeat(auto-fit,minmax(280px,1fr))] gap-5">
            {plans.map((plan) => (
              <li key={plan.id}>
                <Card className="flex h-full flex-col gap-4 p-7">
                  <h2 className="flex items-center gap-3 text-2xl font-extrabold">
                    {plan.name}
                    {plan.id === "pro" && <StatusBadge feature="subscriptions" />}
                  </h2>
                  <p className="text-fg-secondary">{plan.tagline}</p>
                  <p className="text-[1.75rem] font-extrabold">{plan.price}</p>
                  <p className="text-sm text-muted">{plan.priceNote}</p>
                  <ul className="flex list-disc flex-col gap-2 pl-5.5 text-[0.9375rem]">
                    {plan.highlights.map((item) => (
                      <li key={item}>{item}</li>
                    ))}
                  </ul>
                  <div className="mt-auto pt-2">
                    {plan.id === "pro" ? (
                      <FeatureAction
                        feature="subscriptions"
                        label="Get Pro in the app"
                        reason="Pro isn't on sale yet. It will be bought in the JobTrigger app."
                      >
                        <Link
                          href={routes.download}
                          className="inline-flex h-13 items-center rounded-full bg-accent px-5 font-bold text-on-accent no-underline hover:bg-accent-hover hover:text-on-accent"
                        >
                          Get Pro in the app
                        </Link>
                      </FeatureAction>
                    ) : (
                      <Link
                        href={routes.signIn}
                        className="inline-flex h-13 items-center rounded-full border border-line px-5 font-bold text-fg no-underline hover:bg-sunken"
                      >
                        Set up a server
                      </Link>
                    )}
                  </div>
                </Card>
              </li>
            ))}
          </ul>

          <section aria-labelledby="compare-heading" className="flex flex-col gap-4">
            <h2 id="compare-heading" className="text-2xl font-extrabold">
              Free and Pro, side by side
            </h2>
            <div className="overflow-x-auto">
              <table className="w-full min-w-120 border-collapse text-left text-[0.9375rem]">
                <caption className="sr-only">What Free and Pro include</caption>
                <thead>
                  <tr className="border-b border-line">
                    <th scope="col" className="py-3 pr-4 font-bold">
                      Feature
                    </th>
                    <th scope="col" className="px-4 py-3 font-bold">
                      Free
                    </th>
                    <th scope="col" className="px-4 py-3 font-bold">
                      Pro
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {comparison.map((row) => (
                    <tr key={row.label} className="border-b border-line">
                      <th scope="row" className="py-3 pr-4 font-medium">
                        {row.label}
                      </th>
                      <td className="px-4 py-3">
                        <CellText cell={row.free} />
                      </td>
                      <td className="px-4 py-3">
                        <CellText cell={row.pro} />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>

          {studentOffer && (
            <p
              data-testid="student-offer"
              className="rounded-card border border-line bg-sunken px-5 py-4 text-fg-secondary"
            >
              <strong className="text-fg">Students get Pro free for one year.</strong> Verify with a
              university email, or a student ID, in the Account section of the app or on this
              website. It is one free year per person.
            </p>
          )}

          <ul className="flex list-disc flex-col gap-2 pl-5.5 text-fg-secondary">
            {pricingPromises.map((promise) => (
              <li key={promise}>{promise}</li>
            ))}
          </ul>

          <p className="text-sm text-muted">
            Subscriptions renew until cancelled. See the <Link href={routes.terms}>terms</Link> and{" "}
            <Link href={routes.privacy}>privacy policy</Link>.
          </p>
        </Container>
      </Section>
    </main>
  );
}
