import Link from "next/link";

import { ToolTile } from "@/components/tool-tile";
import type { Credential } from "@/domain/credentials";
import { credentialName, toolNames } from "@/domain/tools";

import { deleteServerAction, updateServerAction } from "./actions";
import { DeleteServer } from "./delete-server";
import { ServerForm, type ServerFormValues } from "./server-form";

const formValues = (credential: Credential): ServerFormValues => ({
  name: credentialName(credential),
  url:
    credential.tool === "jenkins"
      ? credential.url
      : credential.tool === "sonarqube"
        ? credential.baseUrl
        : "",
  username: credential.tool === "jenkins" ? credential.username : "",
  owner: credential.tool === "github" ? credential.defaultOwner : "",
  organization: credential.tool === "sonarqube" ? credential.defaultOrganization : "",
});

/** Edit or delete a server (design 12; US-WEB-15). */
export function EditServerView({ credential }: { credential: Credential }) {
  const name = credentialName(credential);
  const toolName = toolNames[credential.tool].name;
  const target = { tool: credential.tool, id: credential.id };

  return (
    <>
      <nav aria-label="Breadcrumb" className="flex gap-2 text-sm text-muted">
        <Link href="/servers" className="font-semibold">
          My servers
        </Link>
        <span aria-hidden="true">/</span>
        <span aria-current="page">{name}</span>
      </nav>
      <div className="flex flex-wrap items-center gap-4">
        <ToolTile tool={credential.tool} size="header" />
        <div className="flex flex-col gap-1">
          <h1 className="text-h3">{name}</h1>
          <span className="flex items-center gap-2 text-[0.8125rem] text-muted">
            {toolName}
            {credential.isDefault && (
              <>
                {" · "}
                <span className="rounded-full bg-success-bg px-2 py-0.5 font-bold text-success-fg">
                  ✓ Active
                </span>
              </>
            )}
          </span>
        </div>
      </div>

      <div className="flex flex-wrap items-start gap-5">
        <ServerForm
          tool={credential.tool}
          action={updateServerAction.bind(null, {
            ...target,
            needsReentry: credential.needsReentry,
          })}
          initial={formValues(credential)}
          editing={!credential.needsReentry}
          submitLabel="Save changes"
          secondary={
            <Link
              href="/servers"
              className="flex h-13 items-center px-3 font-semibold text-muted no-underline"
            >
              Cancel
            </Link>
          }
        />
        <aside className="flex min-w-0 flex-[1_1_280px] flex-col gap-4">
          <div className="flex flex-col gap-2.5 rounded-panel border border-line bg-card p-5.5 text-sm">
            <span className="text-xs font-bold tracking-[0.08em] text-muted uppercase">Token</span>
            {credential.needsReentry ? (
              <span
                role="status"
                className="rounded-control bg-unstable-bg px-3 py-2 text-unstable-fg"
              >
                The saved token can&apos;t be read. Paste it again to use this server.
              </span>
            ) : (
              <>
                <span className="font-mono text-[0.9375rem]">{credential.secretMask}</span>
                <span className="text-muted">Stored encrypted. Never shown in full.</span>
              </>
            )}
          </div>
          <DeleteServer
            name={name}
            toolName={toolName}
            action={deleteServerAction.bind(null, target)}
          />
        </aside>
      </div>
    </>
  );
}
