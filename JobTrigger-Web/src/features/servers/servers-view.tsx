import Link from "next/link";

import { Card } from "@/components/layout";
import { ToolTile } from "@/components/tool-tile";
import { failureMessage, type AppFailure } from "@/domain/app-failure";
import type { Credential } from "@/domain/credentials";
import { credentialAddress, credentialName, toolNames, tools } from "@/domain/tools";

import { MakeActiveButton } from "./make-active-button";
import { addServerHref, editServerHref } from "./server-links";

function PlusIcon() {
  return (
    <svg
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2.4"
      strokeLinecap="round"
      aria-hidden="true"
    >
      <path d="M12 5v14M5 12h14" />
    </svg>
  );
}

function Counts({ servers }: { servers: Credential[] }) {
  return (
    <ul className="grid grid-cols-[repeat(auto-fit,minmax(180px,1fr))] gap-3.5">
      {tools.map((tool) => {
        const count = servers.filter((server) => server.tool === tool).length;
        const names = toolNames[tool];
        return (
          <li
            key={tool}
            className={
              count > 0
                ? "flex items-center gap-3.5 rounded-card border border-line bg-card p-4.5"
                : "flex items-center gap-3.5 rounded-card border border-dashed border-line-strong bg-card p-4.5"
            }
          >
            <ToolTile tool={tool} size="md" />
            <span className="flex flex-col">
              <span className="text-2xl font-extrabold">{count}</span>
              {count > 0 ? (
                <span className="text-[0.8125rem] text-muted">
                  {count === 1 ? names.one : names.many}
                </span>
              ) : (
                <Link href={addServerHref(tool)} className="text-[0.8125rem] font-semibold">
                  Add {names.name} →
                </Link>
              )}
            </span>
          </li>
        );
      })}
    </ul>
  );
}

function ServerTable({ servers }: { servers: Credential[] }) {
  return (
    <Card radius="lg" className="overflow-hidden">
      {/* Scrolls on its own on narrow screens; focusable for keyboard users. */}
      {/* `relative`: the sr-only labels inside are position:absolute and
          would otherwise escape the scroll box and widen the page. */}
      <div role="region" aria-label="Servers" tabIndex={0} className="relative overflow-x-auto">
        <table className="w-full min-w-190 border-collapse text-sm">
          <thead>
            <tr className="border-b border-line bg-page text-left">
              {["Server", "Address", "Token", "Status"].map((heading) => (
                <th
                  key={heading}
                  scope="col"
                  className="px-5 py-3 text-xs font-bold tracking-[0.06em] text-muted uppercase"
                >
                  {heading}
                </th>
              ))}
              <th scope="col" className="px-5 py-3">
                <span className="sr-only">Actions</span>
              </th>
            </tr>
          </thead>
          <tbody>
            {servers.map((server) => (
              <tr
                key={`${server.tool}-${server.id}`}
                className="border-b border-raised last:border-b-0"
              >
                <th scope="row" className="px-5 py-4 text-left">
                  <span className="flex items-center gap-3">
                    <ToolTile tool={server.tool} size="sm" />
                    <span className="flex flex-col gap-0.5">
                      <span className="font-bold">{credentialName(server)}</span>
                      <span className="text-xs font-medium text-muted">
                        {toolNames[server.tool].name}
                      </span>
                    </span>
                  </span>
                </th>
                <td className="px-5 py-4 font-mono text-[0.8125rem] break-all text-fg-secondary">
                  {credentialAddress(server)}
                </td>
                <td className="px-5 py-4 font-mono text-[0.8125rem] text-muted">
                  {server.needsReentry ? (
                    // AUD-63: the stored secret can't be decrypted; paste it again.
                    <span className="rounded-full bg-unstable-bg px-2.5 py-1 font-sans text-xs font-bold text-unstable-fg">
                      Paste again
                    </span>
                  ) : (
                    server.secretMask
                  )}
                </td>
                <td className="px-5 py-4">
                  {server.isDefault ? (
                    <span className="rounded-full bg-success-bg px-2.5 py-1 text-xs font-bold text-success-fg">
                      ✓ Active
                    </span>
                  ) : (
                    <MakeActiveButton
                      tool={server.tool}
                      id={server.id}
                      name={credentialName(server)}
                    />
                  )}
                </td>
                <td className="px-5 py-4 text-right">
                  <Link href={editServerHref(server)} className="font-bold">
                    {/* The space sits outside the span: a leading space inside it is
                        trimmed from the accessible name ("EditAcme…"). */}
                    Edit <span className="sr-only">{credentialName(server)}</span>
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Card>
  );
}

/** My servers (design 10; US-WEB-11). */
export function ServersView({
  servers,
  failure,
}: {
  servers: Credential[];
  failure: AppFailure | null;
}) {
  return (
    <>
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex flex-col gap-1.5">
          <h1 className="text-h3">My servers</h1>
          <p className="text-sm text-muted">
            Changes here show up in the app the next time you open it.
          </p>
        </div>
        <Link
          href={addServerHref()}
          className="flex h-11.5 items-center gap-2 rounded-control bg-accent px-4.5 text-[0.9375rem] font-bold text-on-accent no-underline hover:bg-accent-hover hover:text-on-accent"
        >
          <PlusIcon />
          Add server
        </Link>
      </div>

      {failure ? (
        <div
          role="alert"
          className="flex flex-wrap items-center justify-between gap-4 rounded-2xl bg-failed-bg px-5 py-4.5"
        >
          <span className="text-[0.9375rem] font-semibold text-failed-fg">
            {failureMessage(failure)}
          </span>
          {/* A plain link: works without JavaScript, and reloads fresh (no-store). */}
          <a
            href="/servers"
            className="flex h-11 items-center rounded-control border border-line-strong bg-card px-4 text-sm font-semibold text-fg no-underline hover:text-fg"
          >
            Try again
          </a>
        </div>
      ) : (
        <>
          <Counts servers={servers} />
          {servers.length > 0 ? (
            <ServerTable servers={servers} />
          ) : (
            <Card radius="lg" className="flex flex-col items-start gap-3 p-7">
              <h2 className="text-lg font-bold">No servers yet</h2>
              <p className="text-sm text-muted">
                Add a Jenkins server, GitHub account or SonarQube server, then open the app.
              </p>
              <Link href={addServerHref()} className="font-semibold">
                Add your first server →
              </Link>
            </Card>
          )}
        </>
      )}
    </>
  );
}
