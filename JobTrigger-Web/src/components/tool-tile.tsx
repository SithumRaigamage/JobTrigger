import { cn } from "./cn";

export type Tool = "jenkins" | "github" | "sonarqube";

// A tool's brand colour appears only on its own logo tile (UI-UX tokens).
const marks: Record<Tool, string> = { jenkins: "J", github: "GH", sonarqube: "SQ" };

const sizes = {
  // Logo strip (Home): 32 px.
  sm: { box: "size-8 rounded-[9px]", text: { short: "text-sm", long: "text-xs" } },
  // Tool cards (Integrations): 64 px with a white ring over the card band.
  lg: {
    box: "size-16 rounded-[18px] border-4 border-on-accent",
    text: { short: "text-xl", long: "text-xl" },
  },
} as const;

/**
 * The tool's letter mark on its brand tile. Decorative: name it in text.
 * GitHub has no brand colour of its own here: `light` (on dark strips) or
 * `dark` (on the Integrations cards), as each design shows it.
 */
export function ToolTile({
  tool,
  size = "sm",
  github = "light",
  className,
}: {
  tool: Tool;
  size?: keyof typeof sizes;
  github?: "light" | "dark";
  className?: string;
}) {
  const mark = marks[tool];
  const colour =
    tool === "jenkins"
      ? "bg-brand-jenkins text-on-brand"
      : tool === "sonarqube"
        ? "bg-brand-sonarqube text-on-brand"
        : github === "light"
          ? "bg-fg text-page"
          : "bg-band text-fg";

  return (
    <span
      aria-hidden="true"
      className={cn(
        "flex shrink-0 items-center justify-center font-extrabold",
        sizes[size].box,
        sizes[size].text[mark.length === 1 ? "short" : "long"],
        colour,
        className,
      )}
    >
      {mark}
    </span>
  );
}
