import Link from "next/link";

import { Card } from "@/components/layout";
import { ToolTile } from "@/components/tool-tile";
import { failureMessage, type AppFailure } from "@/domain/app-failure";
import type { Credential } from "@/domain/credentials";
import { isToolReleased, releasedTools } from "@/content/release";
import { credentialAddress, credentialName, toolNames, tools } from "@/domain/tools";

import { MakeActiveButton } from "./make-active-button";
import type { PairCode } from "./pair-codes";
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

function Counts({ servers, preview }: { servers: Credential[]; preview: boolean }) {
  return (
    <ul className="grid grid-cols-[repeat(auto-fit,minmax(180px,1fr))] gap-3.5">
      {/* A tool this release doesn't ship is hidden unless something is
          saved for it, so a saved server is never out of sight. */}
      {tools
        .filter((tool) => isToolReleased(tool) || servers.some((s) => s.tool === tool))
        .map((tool) => {
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
                ) : preview ? (
                  <span className="text-[0.8125rem] text-muted">No {names.name} yet</span>
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

function ServerTable({ servers, preview }: { servers: Credential[]; preview: boolean }) {
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
                  ) : preview ? (
                    <PreviewControl label="Make active" name={credentialName(server)} />
                  ) : (
                    <MakeActiveButton
                      tool={server.tool}
                      id={server.id}
                      name={credentialName(server)}
                    />
                  )}
                </td>
                <td className="px-5 py-4 text-right">
                  {preview ? (
                    <PreviewControl label="Edit" name={credentialName(server)} plain />
                  ) : (
                    <Link href={editServerHref(server)} className="font-bold">
                      {/* The space sits outside the span: a leading space inside it is
                        trimmed from the accessible name ("EditAcme…"). */}
                      Edit <span className="sr-only">{credentialName(server)}</span>
                    </Link>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Card>
  );
}

/**
 * A control the demo shows but does not run (E2, PE-16): disabled, with no
 * form and no link, so nothing here can call a server action.
 */
function PreviewControl({ label, name, plain }: { label: string; name: string; plain?: boolean }) {
  return (
    <button
      type="button"
      aria-disabled="true"
      title="Not available in the demo"
      className={
        plain
          ? "cursor-not-allowed font-bold text-muted"
          : "h-9 cursor-not-allowed rounded-[10px] border border-dashed border-line-strong px-3 text-[0.8125rem] font-semibold text-muted"
      }
    >
      {label} <span className="sr-only">{name}</span>
    </button>
  );
}

/**
 * My servers (design 10; US-WEB-11). With `preview` (the public /demo page,
 * E2 PE-16) the same view renders sample data and its controls are inert.
 */
export function ServersView({
  servers,
  failure,
  preview = false,
  pairCodes = [],
}: {
  servers: Credential[];
  failure: AppFailure | null;
  preview?: boolean;
  /** NR-03: one QR per Jenkins server, generated by the page. */
  pairCodes?: PairCode[];
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
        {preview ? (
          <button
            type="button"
            aria-disabled="true"
            title="Not available in the demo"
            className="flex h-11.5 cursor-not-allowed items-center gap-2 rounded-control border border-dashed border-line-strong px-4.5 text-[0.9375rem] font-bold text-muted"
          >
            <PlusIcon />
            Add server
          </button>
        ) : (
          <Link
            href={addServerHref()}
            className="flex h-11.5 items-center gap-2 rounded-control bg-accent px-4.5 text-[0.9375rem] font-bold text-on-accent no-underline hover:bg-accent-hover hover:text-on-accent"
          >
            <PlusIcon />
            Add server
          </Link>
        )}
      </div>

      {failure ? (
        <div
          role="alert"
          className="flex flex-wrap items-center justify-between gap-4 rounded-2xl bg-failed-bg px-5 py-4.5"
        >
          <span className="text-[0.9375rem] font-semibold text-failed-fg">
            {failureMessage(failure)}
          </span>
          {/* Works without JavaScript; with it, re-renders this dynamic page. */}
          <Link
            href="/servers"
            className="flex h-11 items-center rounded-control border border-line-strong bg-card px-4 text-sm font-semibold text-fg no-underline hover:text-fg"
          >
            Try again
          </Link>
        </div>
      ) : (
        <>
          <Counts servers={servers} preview={preview} />
          {servers.length > 0 ? (
            <ServerTable servers={servers} preview={preview} />
          ) : (
            <Card radius="lg" className="flex flex-col items-start gap-3 p-7">
              <h2 className="text-lg font-bold">No servers yet</h2>
              <p className="text-sm text-muted">Add {addableTools()}, then open the app.</p>
              <Link href={addServerHref()} className="font-semibold">
                Add your first server →
              </Link>
            </Card>
          )}
          {/* NR-03: a code per saved Jenkins server, so nobody types a URL
              on a phone. Hidden in the demo, like every other control. */}
          {!preview && pairCodes.length > 0 && (
            <section aria-labelledby="pair-heading" className="flex flex-col gap-3">
              <h2 id="pair-heading" className="text-lg font-bold">
                Pair with your phone
              </h2>
              <p className="max-w-150 text-sm text-muted">
                Point the iPhone Camera, or your Android camera, at a code to open that server in
                JobTrigger with the address already filled in. The token is never in the code — you
                type it in the app.
              </p>
              <div className="flex flex-wrap gap-4">
                {pairCodes.map((code) => (
                  <figure
                    key={code.id}
                    className="flex w-44 flex-col items-center gap-2 rounded-card border border-line bg-card p-3.5"
                  >
                    {/* Our own SVG, generated from the link on the server. */}
                    <div aria-hidden="true" dangerouslySetInnerHTML={{ __html: code.svg }} />
                    <figcaption className="w-full truncate text-center text-xs font-bold">
                      {code.name}
                    </figcaption>
                    <span className="w-full text-center text-[0.6875rem] leading-snug text-muted">
                      Scan with your phone’s camera
                    </span>
                  </figure>
                ))}
              </div>
            </section>
          )}
        </>
      )}
    </>
  );
}

/** "a Jenkins server, GitHub account or SonarQube server": the released tools only. */
function addableTools(): string {
  const names = releasedTools().map((tool) => toolNames[tool].one);
  if (names.length <= 1) return `a ${names[0] ?? "server"}`;
  return `a ${names.slice(0, -1).join(", ")} or ${names.at(-1)}`;
}
