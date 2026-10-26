import { Container, Section } from "@/components/layout";
import { StatusBadge } from "@/components/status-badge";
import { ToolTile } from "@/components/tool-tile";
import { statusOf } from "@/content/feature-status";

/** "One app for" strip under the hero (designs 01 / 18). */
export function ToolStrip() {
  // "More planned" only while some tool is still `planned` (WEB-B7).
  const anyToolPlanned = (["gitlab-ci", "circleci"] as const).some(
    (id) => statusOf(id) === "planned",
  );

  return (
    <Section surface="dark" aria-label="Supported tools" className="border-b border-line bg-band">
      <Container className="flex flex-wrap items-center justify-center gap-x-12 gap-y-4 py-7 text-[1.0625rem] font-bold text-fg-secondary">
        <span className="text-[0.8125rem] font-medium text-muted">One app for</span>
        <span className="flex items-center gap-2.5">
          <ToolTile tool="jenkins" />
          Jenkins
        </span>
        <span className="flex items-center gap-2.5">
          <ToolTile tool="github" />
          GitHub Actions <StatusBadge feature="github-runs" />
        </span>
        <span className="flex items-center gap-2.5">
          <ToolTile tool="sonarqube" />
          SonarQube <StatusBadge feature="sonarqube-insights" />
        </span>
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
