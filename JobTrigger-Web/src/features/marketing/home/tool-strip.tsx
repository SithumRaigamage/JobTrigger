import { Container, Section } from "@/components/layout";
import { StatusBadge } from "@/components/status-badge";
import { ToolTile } from "@/components/tool-tile";
import { statusOf, type FeatureId } from "@/content/feature-status";
import { comingNextTools, releasedInOrder } from "@/content/tool-copy";
import type { Tool } from "@/domain/credentials";

const labels: Record<Tool, string> = {
  jenkins: "Jenkins",
  github: "GitHub Actions",
  sonarqube: "SonarQube",
};

/** The build-status badge a released tool shows (none for Jenkins). */
const badges: Partial<Record<Tool, FeatureId>> = {
  github: "github-actions",
  sonarqube: "sonarqube-insights",
};

/**
 * "One app for" strip under the hero (designs 01 / 18). It leads with the
 * tools this release ships (release/tools.json); tools with code that a later
 * release ships come after, named only as "coming next" with their release.
 */
export function ToolStrip() {
  // "More planned" only while some tool is still `planned` (WEB-B7).
  const anyToolPlanned = (["gitlab-ci", "circleci"] as const).some(
    (id) => statusOf(id) === "planned",
  );
  const next = comingNextTools();

  return (
    <Section surface="dark" aria-label="Supported tools" className="border-b border-line bg-band">
      <Container className="flex flex-wrap items-center justify-center gap-x-12 gap-y-4 py-7 text-[1.0625rem] font-bold text-fg-secondary">
        <span className="text-[0.8125rem] font-medium text-muted">One app for</span>
        {releasedInOrder().map((tool) => (
          <span key={tool} className="flex items-center gap-2.5">
            <ToolTile tool={tool} />
            {labels[tool]}
            {badges[tool] && <StatusBadge feature={badges[tool]} />}
          </span>
        ))}
        {next.length > 0 && (
          <>
            <span className="text-[0.8125rem] font-medium text-muted">Coming next</span>
            {next.map(({ tool, name, version }) => (
              <span key={tool} className="flex items-center gap-2.5 font-medium text-muted">
                <ToolTile tool={tool} />
                {name}
                <span className="text-[0.8125rem] font-semibold">{version}</span>
              </span>
            ))}
          </>
        )}
        {anyToolPlanned && (
          <span className="flex items-center gap-2.5 font-medium text-muted">
            <span
              aria-hidden="true"
              className="flex size-8 items-center justify-center rounded-[9px] border border-dashed border-line-strong"
            >
              +
            </span>
            More planned
          </span>
        )}
      </Container>
    </Section>
  );
}
