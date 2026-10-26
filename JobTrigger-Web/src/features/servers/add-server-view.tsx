import Link from "next/link";

import { cn } from "@/components/cn";
import { FeatureAction } from "@/components/feature-action";
import { ToolTile } from "@/components/tool-tile";
import { statusOf } from "@/content/feature-status";
import type { Tool } from "@/domain/credentials";
import { toolNames, tools } from "@/domain/tools";

import { addServerAction } from "./actions";
import { ServerForm } from "./server-form";
import { addServerHref } from "./server-links";
import { Steps } from "./steps";
import { toolHelp, toolNeeds } from "./tool-help";

/** "How do I get this?" (design 11; US-WEB-16). */
export function TokenHelp({ tool }: { tool: Tool }) {
  const help = toolHelp[tool];
  return (
    <aside
      id="help"
      aria-labelledby="help-heading"
      data-surface="dark"
      className="flex min-w-0 flex-[1_1_300px] flex-col gap-4 rounded-panel p-7"
    >
      <span className="text-kicker text-running-fg uppercase">How do I get this?</span>
      <h2 id="help-heading" className="text-xl font-extrabold">
        {help.title}
      </h2>
      <ol className="flex flex-col">
        {help.steps.map((step, index) => (
          <li key={step} className="flex gap-3.5">
            <span className="flex flex-col items-center">
              <span
                aria-hidden="true"
                className="flex size-6.5 flex-none items-center justify-center rounded-full bg-running-bg text-xs font-extrabold text-running-fg"
              >
                {index + 1}
              </span>
              <span
                className={cn(
                  "my-1 w-0.5 flex-1",
                  index < help.steps.length - 1 ? "bg-line" : "bg-transparent",
                )}
              />
            </span>
            <span className="pt-0.5 pb-4 text-sm leading-[1.55] text-fg-secondary">{step}</span>
          </li>
        ))}
      </ol>
      <p className="mt-auto rounded-control bg-unstable-bg px-3.5 py-3 text-[0.8125rem] leading-normal text-unstable-fg">
        {help.tip}
      </p>
    </aside>
  );
}

/** Add a server (designs 11 / 22; US-WEB-12, 13, 14, 16). */
export function AddServerView({ tool }: { tool: Tool }) {
  return (
    <>
      <div className="flex flex-col gap-4">
        <h1 className="text-h3">Add a server</h1>
        <Steps
          current={2}
          last={statusOf("app-stores") === "live" ? "Open the app" : "Install the app · soon"}
        />
      </div>

      {/* Links, not client state: works without JS and the server renders the
          chosen tool's form. */}
      <nav aria-label="Tool" className="grid grid-cols-[repeat(auto-fit,minmax(180px,1fr))] gap-3">
        {tools.map((option) => {
          const current = option === tool;
          return (
            <Link
              key={option}
              href={addServerHref(option)}
              aria-current={current ? "page" : undefined}
              className={cn(
                "flex min-h-18 items-center gap-3 rounded-card bg-card px-4 py-3.5 text-fg no-underline hover:text-fg",
                current ? "border-2 border-accent ring-4 ring-accent/15" : "border border-line",
              )}
            >
              <ToolTile tool={option} size="md" />
              <span className="flex flex-col gap-0.5">
                <span className="text-[0.9375rem] font-bold">{toolNames[option].name}</span>
                <span className="text-xs font-medium text-muted">{toolNeeds[option]}</span>
              </span>
            </Link>
          );
        })}
      </nav>

      <div className="flex flex-wrap items-stretch gap-5">
        <ServerForm
          key={tool}
          tool={tool}
          action={addServerAction}
          submitLabel="Save server"
          secondary={
            <FeatureAction
              feature="web-test-connection"
              label="Test connection"
              reason="You can test the connection from the app after saving."
            >
              {/* US-WEB-19 ships with its backend endpoint. */}
              <span />
            </FeatureAction>
          }
        />
        <TokenHelp tool={tool} />
      </div>
    </>
  );
}
