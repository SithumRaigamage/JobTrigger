import { Fragment } from "react";

import { cn } from "@/components/cn";

/** The 3-step tracker of designs 11 and 13: done, current, upcoming. */
export function Steps({ current, last }: { current: 1 | 2 | 3; last: string }) {
  const labels = ["Choose a tool", "Paste details", last];

  return (
    <ol
      aria-label="Steps"
      className="flex flex-wrap items-center gap-2.5 text-[0.8125rem] font-semibold"
    >
      {labels.map((label, index) => {
        const step = index + 1;
        const done = step < current;
        const isCurrent = step === current;
        return (
          <Fragment key={label}>
            {index > 0 && (
              // Connectors are their own hidden items (as in the design), so
              // each step keeps normal list-item semantics.
              <li
                aria-hidden="true"
                className={cn(
                  "h-0.5 w-8",
                  step <= current ? (done ? "bg-live-dot" : "bg-accent") : "bg-line-strong",
                )}
              />
            )}
            <li
              aria-current={isCurrent ? "step" : undefined}
              className={cn(
                "flex items-center gap-2",
                done ? "text-success-fg" : isCurrent ? "text-running-fg" : "text-muted",
              )}
            >
              <span
                aria-hidden="true"
                className={cn(
                  "flex size-6 items-center justify-center rounded-full",
                  done ? "bg-success-bg" : isCurrent ? "bg-accent text-on-accent" : "bg-line",
                )}
              >
                {done ? "✓" : step}
              </span>
              {done && <span className="sr-only">Done: </span>}
              {label}
            </li>
          </Fragment>
        );
      })}
    </ol>
  );
}
