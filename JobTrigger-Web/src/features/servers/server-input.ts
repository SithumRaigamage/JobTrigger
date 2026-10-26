import type { Tool } from "@/domain/credentials";
import { normalizeServerUrl, serverUrlProblem } from "@/domain/server-url";
import type { GitHubInput, JenkinsInput, SonarQubeInput } from "@/server/credentials-api";

/*
 * Turns a submitted server form into the backend input for its tool, with
 * the app's trimming and rules (the credential edit sheets in
 * JobTrigger-Frontend/lib/presentation/features/settings). Pure: shared by
 * the add (P15-17) and edit (P15-18) actions, unit-tested on its own.
 */

export type FieldErrors = Partial<Record<"name" | "url" | "username" | "secret", string>>;

export type ParsedServer =
  | { ok: true; tool: "jenkins"; input: JenkinsInput }
  | { ok: true; tool: "github"; input: GitHubInput }
  | { ok: true; tool: "sonarqube"; input: SonarQubeInput }
  | { ok: false; fields: FieldErrors };

const text = (form: FormData, key: string) => String(form.get(key) ?? "").trim();

/**
 * [editing]: the saved secret is kept when its field is left blank
 * (US-WEB-15), so a blank secret is fine then.
 */
export function parseServerForm(tool: Tool, form: FormData, editing = false): ParsedServer {
  const fields: FieldErrors = {};
  const name = text(form, "name");
  const secret = text(form, "secret");
  if (!name) fields.name = tool === "jenkins" ? "Enter a name for this server." : "Enter a label.";
  if (!secret && !editing) {
    fields.secret = tool === "jenkins" ? "Paste the API token." : "Paste the token.";
  }

  if (tool === "jenkins") {
    const url = text(form, "url");
    const username = text(form, "username");
    const urlProblem = serverUrlProblem(url, "Jenkins");
    if (urlProblem) fields.url = urlProblem;
    if (!username) fields.username = "Enter your Jenkins username.";
    if (Object.keys(fields).length > 0) return { ok: false, fields };
    return {
      ok: true,
      tool,
      input: {
        name,
        url: normalizeServerUrl(url),
        username,
        password: secret,
        paramToken: text(form, "paramToken"),
      },
    };
  }

  if (tool === "github") {
    if (Object.keys(fields).length > 0) return { ok: false, fields };
    return {
      ok: true,
      tool,
      input: { label: name, token: secret, defaultOwner: text(form, "owner") },
    };
  }

  const url = text(form, "url");
  const urlProblem = serverUrlProblem(url, "SonarQube");
  if (urlProblem) fields.url = urlProblem;
  if (Object.keys(fields).length > 0) return { ok: false, fields };
  return {
    ok: true,
    tool,
    input: {
      label: name,
      baseUrl: normalizeServerUrl(url),
      token: secret,
      defaultOrganization: text(form, "organization"),
    },
  };
}
