import { cn } from "@/components/cn";
import { Card, Container, Kicker, Section } from "@/components/layout";
import { StatusBadge } from "@/components/status-badge";
import { ToolTile, type Tool } from "@/components/tool-tile";
import { features, statusLabels, statusOf, type FeatureId } from "@/content/feature-status";

import { routes } from "../site-links";

import { toolRequestHref } from "./tool-request";

type ToolCard = {
  tool: Tool;
  name: string;
  /** Band colour, read on the dark token set. */
  band: string;
  badge: FeatureId | "full";
  blurb: string;
  needs: string;
};

function toolCards(): ToolCard[] {
  return [
    {
      tool: "jenkins",
      name: "Jenkins",
      band: "bg-page",
      badge: "full",
      blurb:
        "Jobs, folders and multibranch, every parameter type, live logs, stages, tests, history, queue and nodes.",
      needs: "URL · username · API token",
    },
    {
      tool: "github",
      name: "GitHub Actions",
      band: "bg-raised",
      badge: "github-actions",
      blurb:
        statusOf("github-runs") === "live"
          ? "Repositories, workflows, runs, logs and history across several accounts."
          : "Repositories and workflows across several accounts. Runs, logs and history coming soon.",
      needs: "personal access token",
    },
    {
      tool: "sonarqube",
      name: "SonarQube",
      band: "bg-running-bg",
      badge: "sonarqube-insights",
      blurb:
        statusOf("sonarqube-insights") === "live"
          ? "Projects, quality gates, measures and issues for every saved server."
          : "Save your SonarQube server now. Projects, quality gates, measures and issues are coming soon.",
      needs: "server URL · user token",
    },
  ];
}

/** A comparison cell: a feature's status, or "n/a" when it doesn't apply. */
type Cell = FeatureId | null;

const rows: { capability: string; jenkins: Cell; github: Cell; sonarqube: Cell }[] = [
  {
    capability: "Save servers / accounts",
    jenkins: "jenkins-core",
    github: "github-accounts",
    sonarqube: "sonarqube-save",
  },
  {
    capability: "Browse projects",
    jenkins: "jenkins-core",
    github: "github-accounts",
    sonarqube: "sonarqube-insights",
  },
  {
    capability: "Trigger with parameters",
    jenkins: "jenkins-core",
    github: "github-runs",
    sonarqube: null,
  },
  { capability: "Live logs", jenkins: "jenkins-core", github: "github-runs", sonarqube: null },
  {
    capability: "Stages and test results",
    jenkins: "jenkins-core",
    github: "github-runs",
    sonarqube: null,
  },
  { capability: "Quality gates", jenkins: null, github: null, sonarqube: "sonarqube-insights" },
  {
    capability: "Notifications",
    jenkins: "jenkins-extended",
    github: "github-runs",
    sonarqube: null,
  },
  {
    capability: "Several accounts",
    jenkins: "jenkins-core",
    github: "github-accounts",
    sonarqube: "sonarqube-save",
  },
];

function StatusCell({ feature }: { feature: Cell }) {
  if (feature === null) return <span className="text-[0.8125rem] text-muted">— n/a</span>;
  const status = statusOf(feature);
  const label = status === "live" ? "✓ Yes" : status === "soon" ? "Soon" : statusLabels[status];
  return (
    <span
      className={cn(
        "rounded-full px-2.5 py-1 text-[0.8125rem] font-semibold whitespace-nowrap",
        status === "live" && "bg-success-bg text-success-fg",
        status === "beta" && "bg-running-bg text-running-fg",
        (status === "soon" || status === "planned") && "bg-neutral-bg text-neutral-fg",
      )}
    >
      {label}
    </span>
  );
}

/** Integrations page (designs 03 / 20; US-WEB-04). */
export function IntegrationsView({ supportEmail }: { supportEmail: string | null }) {
  const planned = (["gitlab-ci", "circleci"] as const)
    .filter((id) => statusOf(id) === "planned")
    .map((id) => features[id].label);

  return (
    <main className="flex flex-1 flex-col">
      <Section surface="dark" dotGrid>
        <Container className="flex flex-col items-center gap-5 pt-24 pb-38 text-center">
          <Kicker>Integrations</Kicker>
          <h1 className="text-h1">Plays well with your CI.</h1>
          <p className="max-w-140 text-[1.1875rem] leading-relaxed text-fg-secondary">
            Exactly what works today, and what&apos;s coming. Nothing more, nothing less.
          </p>
        </Container>
      </Section>

      <Container className="-mt-24 flex flex-col gap-14 pb-26">
        <ul className="flex flex-wrap gap-5">
          {toolCards().map((card) => (
            <li key={card.tool} className="min-w-0 flex-[1_1_320px]">
              <article className="flex h-full flex-col overflow-hidden rounded-3xl border border-line bg-card shadow-lift">
                <div data-surface="dark" className={cn("flex h-24 items-end px-6.5", card.band)}>
                  <ToolTile tool={card.tool} size="lg" github="blend" className="-mb-8" />
                </div>
                <div className="flex flex-col gap-2.5 px-6.5 pt-6 pb-7">
                  <div className="flex flex-wrap items-center gap-2.5">
                    <h2 className="text-[1.375rem] font-extrabold">{card.name}</h2>
                    {card.badge === "full" ? (
                      <span className="rounded-full bg-success-bg px-2.5 py-0.75 text-xs font-bold text-success-fg">
                        Full support
                      </span>
                    ) : (
                      <StatusBadge feature={card.badge} size="md" />
                    )}
                  </div>
                  <p className="text-[0.9375rem] leading-relaxed text-muted">{card.blurb}</p>
                  <p className="pt-2.5 font-mono text-xs text-muted">Needs: {card.needs}</p>
                </div>
              </article>
            </li>
          ))}
        </ul>

        <section aria-labelledby="compare-heading" className="flex flex-col gap-4.5">
          <h2 id="compare-heading" className="text-[2rem] font-extrabold tracking-[-0.03em]">
            Compare
          </h2>
          {/* Scrolls on its own on narrow screens; focusable so keyboard
              users can scroll it too (WEB-B5). */}
          <Card
            radius="lg"
            role="region"
            aria-labelledby="compare-heading"
            tabIndex={0}
            className="overflow-x-auto"
          >
            <table className="w-full min-w-170 border-collapse text-[0.9375rem]">
              <thead>
                <tr className="border-b border-line text-left">
                  {["Capability", "Jenkins", "GitHub Actions", "SonarQube"].map((heading) => (
                    <th
                      key={heading}
                      scope="col"
                      className="px-5.5 py-4 text-[0.8125rem] font-semibold text-muted"
                    >
                      {heading}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => (
                  <tr key={row.capability} className="border-b border-raised last:border-b-0">
                    <th scope="row" className="px-5.5 py-3.5 text-left font-semibold">
                      {row.capability}
                    </th>
                    <td className="px-5.5 py-3.5">
                      <StatusCell feature={row.jenkins} />
                    </td>
                    <td className="px-5.5 py-3.5">
                      <StatusCell feature={row.github} />
                    </td>
                    <td className="px-5.5 py-3.5">
                      <StatusCell feature={row.sonarqube} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Card>
          {planned.length > 0 && (
            <p className="text-[0.8125rem] text-muted">
              Planned, no date yet: {planned.join(" and ")}.
            </p>
          )}
        </section>

        <section
          id="request"
          aria-labelledby="request-heading"
          className="relative overflow-hidden rounded-[28px] bg-accent text-on-accent"
        >
          <div
            aria-hidden="true"
            className="absolute -top-15 -right-20 size-80 rounded-full border-40 border-on-accent/12"
          />
          <div className="relative flex flex-wrap items-center justify-between gap-6 p-8 md:p-12">
            <div className="flex min-w-0 flex-[1_1_420px] flex-col gap-2.5">
              <h2 id="request-heading" className="text-4xl font-extrabold tracking-[-0.03em]">
                Using something else?
              </h2>
              <p className="text-[1.0625rem] leading-relaxed">
                Tell us which tool you need. Requests from the app and this page land in the same
                place.
              </p>
            </div>
            <a
              href={supportEmail ? toolRequestHref(supportEmail) : routes.support}
              className="flex h-13 items-center rounded-full bg-on-accent px-6 font-bold text-accent-hover no-underline hover:text-accent-hover"
            >
              Request a tool →
            </a>
          </div>
        </section>
      </Container>
    </main>
  );
}
