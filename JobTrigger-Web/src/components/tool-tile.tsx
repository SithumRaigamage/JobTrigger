import { cn } from "./cn";

export type Tool = "jenkins" | "github" | "sonarqube";

// A tool's brand colour appears only on its own logo tile (UI-UX tokens).
// GitHub's tile inverts with the surface: light on dark, dark on light.
const tiles: Record<Tool, { mark: string; className: string }> = {
  jenkins: { mark: "J", className: "bg-brand-jenkins text-on-brand text-sm" },
  github: { mark: "GH", className: "bg-fg text-page text-xs" },
  sonarqube: { mark: "SQ", className: "bg-brand-sonarqube text-on-brand text-xs" },
};

/** The tool's letter mark on its brand tile. Decorative: name it in text. */
export function ToolTile({ tool, className }: { tool: Tool; className?: string }) {
  const tile = tiles[tool];
  return (
    <span
      aria-hidden="true"
      className={cn(
        "flex size-8 shrink-0 items-center justify-center rounded-[9px] font-extrabold",
        tile.className,
        className,
      )}
    >
      {tile.mark}
    </span>
  );
}
