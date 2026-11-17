"use client";

import { useActionState, useState, type ReactNode } from "react";

import { Field, Notice, PasswordField, SubmitButton } from "@/components/form";
import type { Tool } from "@/domain/credentials";
import { isCleartextUrl } from "@/domain/server-url";

import type { ServerFormState } from "./actions";

/** What the edit page knows about the saved server (never its secret). */
export type ServerFormValues = {
  name: string;
  url: string;
  username: string;
  owner: string;
  organization: string;
};

const empty: ServerFormValues = { name: "", url: "", username: "", owner: "", organization: "" };

const labels: Record<Tool, { name: string; url: string; secret: string; secretName: string }> = {
  jenkins: { name: "Name", url: "Server URL", secret: "API token", secretName: "API token" },
  github: { name: "Label", url: "", secret: "Personal access token", secretName: "token" },
  sonarqube: { name: "Label", url: "Instance URL", secret: "User token", secretName: "token" },
};

const cleartext: Record<Tool, string> = {
  jenkins: "your username and password or token are",
  github: "",
  sonarqube: "your token is",
};

/**
 * One server form for every tool, fields and labels as in the app's
 * credential sheets (US-WEB-12–15). Controlled inputs: React resets an
 * uncontrolled form after an action, which would lose what was typed when
 * a save fails. Secrets are never pre-filled (US-WEB-15).
 */
export function ServerForm({
  tool,
  action,
  initial = empty,
  editing = false,
  submitLabel,
  secondary,
}: {
  tool: Tool;
  action: (state: ServerFormState, form: FormData) => Promise<ServerFormState>;
  initial?: ServerFormValues;
  editing?: boolean;
  submitLabel: string;
  /** Next to the submit button, e.g. Test connection or Delete. */
  secondary?: ReactNode;
}) {
  const [state, formAction, pending] = useActionState(action, {});
  const [values, setValues] = useState<ServerFormValues>({
    ...initial,
    url: initial.url || (tool === "sonarqube" ? "https://sonarcloud.io" : ""),
  });
  const [secret, setSecret] = useState("");
  const [paramToken, setParamToken] = useState("");
  const set = (key: keyof ServerFormValues) => (event: React.ChangeEvent<HTMLInputElement>) =>
    setValues((current) => ({ ...current, [key]: event.target.value }));
  const label = labels[tool];
  const secretHint = editing
    ? "Leave blank to keep the saved token."
    : "Sent once, encrypted, never shown again in full.";

  return (
    <form
      action={formAction}
      noValidate
      className="flex min-w-0 flex-[999_1_440px] flex-col gap-4.5 rounded-panel border border-line bg-card p-6 shadow-card sm:p-7.5"
    >
      <input type="hidden" name="tool" value={tool} />
      {state.error && <Notice tone="error">{state.error}</Notice>}
      <Field
        id="name"
        name="name"
        label={label.name}
        value={values.name}
        onChange={set("name")}
        placeholder={tool === "jenkins" ? "My Jenkins server" : "Personal, Work org, etc."}
        error={state.fields?.name}
      />
      {tool !== "github" && (
        <Field
          id="url"
          name="url"
          type="url"
          inputMode="url"
          spellCheck={false}
          label={label.url}
          value={values.url}
          onChange={set("url")}
          placeholder={tool === "jenkins" ? "https://ci.example.com" : "https://sonarcloud.io"}
          className="font-mono"
          error={state.fields?.url}
          notice={
            isCleartextUrl(values.url) && (
              // AUD-14 / AUD-52: http:// is allowed, never silently.
              <span
                role="status"
                className="block rounded-control bg-unstable-bg px-3 py-2 text-[0.8125rem] text-unstable-fg"
              >
                Not encrypted: {cleartext[tool]} sent in plain text with every request. Use https://
                unless this server is only reachable on a network you trust.
              </span>
            )
          }
        />
      )}
      {tool === "jenkins" && (
        <Field
          id="username"
          name="username"
          label="Username"
          autoComplete="off"
          spellCheck={false}
          value={values.username}
          onChange={set("username")}
          error={state.fields?.username}
        />
      )}
      <PasswordField
        id="secret"
        name="secret"
        label={label.secret}
        secretName={label.secretName}
        autoComplete="off"
        spellCheck={false}
        value={secret}
        onChange={(event) => setSecret(event.target.value)}
        error={state.fields?.secret}
        hint={
          <span className="flex items-center gap-1.5 text-[0.8125rem] text-muted">
            <svg
              width="14"
              height="14"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              aria-hidden="true"
            >
              <rect x="4" y="10" width="16" height="11" rx="2" />
              <path d="M8 10V7a4 4 0 0 1 8 0v3" />
            </svg>
            {secretHint}
          </span>
        }
      />
      {tool === "jenkins" && (
        <PasswordField
          id="paramToken"
          name="paramToken"
          label="Build token (optional)"
          secretName="build token"
          autoComplete="off"
          spellCheck={false}
          value={paramToken}
          onChange={(event) => setParamToken(event.target.value)}
          hint={
            editing ? (
              <span className="text-[0.8125rem] text-muted">
                Leave blank to keep the saved one.
              </span>
            ) : undefined
          }
        />
      )}
      {tool === "github" && (
        <Field
          id="owner"
          name="owner"
          label="Default org or owner (optional)"
          spellCheck={false}
          placeholder="octocat"
          value={values.owner}
          onChange={set("owner")}
        />
      )}
      {tool === "sonarqube" && (
        <Field
          id="organization"
          name="organization"
          label="Organization (optional)"
          spellCheck={false}
          value={values.organization}
          onChange={set("organization")}
        />
      )}
      <div className="flex flex-wrap items-start gap-2.5 pt-1">
        <SubmitButton pending={pending}>
          <span className="px-3">{pending ? "Saving…" : submitLabel}</span>
        </SubmitButton>
        {secondary}
      </div>
    </form>
  );
}
