import "server-only";

import { z } from "zod";

import type { GitHubAccount, JenkinsServer, SonarQubeServer, Tool } from "@/domain/credentials";
import { ok, type Result } from "@/domain/result";

import { callBackend } from "./backend-client";

/*
 * The three credential collections (docs/api-reference.md §1). Since E4
 * (PE-35) the backend returns a mask and never a secret, so there is
 * nothing to hide here. The portal does not call the decrypted-secret
 * endpoint (`GET …/:id/secret`, for the app only), and nothing in this
 * file may: credentials-api.test.ts fails if it does. The raw shapes below
 * are not exported.
 */

const base = {
  _id: z.string(),
  isDefault: z.boolean(),
  // AUD-63: an unreadable secret comes back null with needsReentry: true.
  needsReentry: z.boolean().optional().default(false),
};

/** "••••" + last 4, made by the backend; null when the secret is unreadable. */
const secretMask = z.string().nullable().optional().default(null);

const jenkinsDto = z.object({
  ...base,
  serverName: z.string(),
  jenkinsURL: z.string(),
  username: z.string(),
  secretMask,
  /** Whether an optional build-trigger token is saved. */
  hasParamToken: z.boolean().optional().default(false),
});

const githubDto = z.object({
  ...base,
  label: z.string(),
  secretMask,
  defaultOwner: z.string().optional().default(""),
});

const sonarDto = z.object({
  ...base,
  label: z.string(),
  baseUrl: z.string(),
  secretMask,
  defaultOrganization: z.string().optional().default(""),
});

function toJenkins(dto: z.infer<typeof jenkinsDto>): JenkinsServer {
  return {
    tool: "jenkins",
    id: dto._id,
    name: dto.serverName,
    url: dto.jenkinsURL,
    username: dto.username,
    isDefault: dto.isDefault,
    needsReentry: dto.needsReentry,
    secretMask: dto.needsReentry ? null : dto.secretMask,
    hasParamToken: dto.hasParamToken,
  };
}

function toGitHub(dto: z.infer<typeof githubDto>): GitHubAccount {
  return {
    tool: "github",
    id: dto._id,
    label: dto.label,
    defaultOwner: dto.defaultOwner,
    isDefault: dto.isDefault,
    needsReentry: dto.needsReentry,
    secretMask: dto.needsReentry ? null : dto.secretMask,
  };
}

function toSonar(dto: z.infer<typeof sonarDto>): SonarQubeServer {
  return {
    tool: "sonarqube",
    id: dto._id,
    label: dto.label,
    baseUrl: dto.baseUrl,
    defaultOrganization: dto.defaultOrganization,
    isDefault: dto.isDefault,
    needsReentry: dto.needsReentry,
    secretMask: dto.needsReentry ? null : dto.secretMask,
  };
}

const paths = {
  jenkins: "/api/credentials",
  github: "/api/github-credentials",
  sonarqube: "/api/sonarqube-credentials",
} as const satisfies Record<Tool, `/api/${string}`>;

const map = <A, B>(result: Result<A>, f: (a: A) => B): Result<B> =>
  result.ok ? ok(f(result.value)) : result;

/* ---- reads ---- */

export async function listJenkins(accessToken: string) {
  return map(await callBackend({ path: paths.jenkins, accessToken }, z.array(jenkinsDto)), (rows) =>
    rows.map(toJenkins),
  );
}

export async function listGitHub(accessToken: string) {
  return map(await callBackend({ path: paths.github, accessToken }, z.array(githubDto)), (rows) =>
    rows.map(toGitHub),
  );
}

export async function listSonarQube(accessToken: string) {
  return map(await callBackend({ path: paths.sonarqube, accessToken }, z.array(sonarDto)), (rows) =>
    rows.map(toSonar),
  );
}

/* ---- writes ---- */

export type JenkinsInput = {
  name: string;
  url: string;
  username: string;
  /** Password or API token. On update, empty keeps the saved one. */
  password: string;
  /** Optional build-trigger token. On update, empty keeps the saved one. */
  paramToken: string;
  isDefault?: boolean;
};

export type GitHubInput = {
  label: string;
  /** On update, empty keeps the saved one. */
  token: string;
  defaultOwner: string;
  isDefault?: boolean;
};

export type SonarQubeInput = {
  label: string;
  baseUrl: string;
  /** On update, empty keeps the saved one. */
  token: string;
  defaultOrganization: string;
  isDefault?: boolean;
};

/** A secret field for the request body: omitted when blank on update (US-WEB-15). */
const secretField = (name: string, value: string, update: boolean) =>
  update && value === "" ? {} : { [name]: value };

function jenkinsBody(input: JenkinsInput, update: boolean) {
  return {
    serverName: input.name,
    jenkinsURL: input.url,
    username: input.username,
    ...secretField("password", input.password, update),
    ...secretField("paramToken", input.paramToken, update),
    ...(input.isDefault !== undefined ? { isDefault: input.isDefault } : {}),
  };
}

function githubBody(input: GitHubInput, update: boolean) {
  return {
    label: input.label,
    defaultOwner: input.defaultOwner,
    ...secretField("token", input.token, update),
    ...(input.isDefault !== undefined ? { isDefault: input.isDefault } : {}),
  };
}

function sonarBody(input: SonarQubeInput, update: boolean) {
  return {
    label: input.label,
    baseUrl: input.baseUrl,
    defaultOrganization: input.defaultOrganization,
    ...secretField("token", input.token, update),
    ...(input.isDefault !== undefined ? { isDefault: input.isDefault } : {}),
  };
}

export async function createJenkins(accessToken: string, input: JenkinsInput) {
  return map(
    await callBackend(
      { method: "POST", path: paths.jenkins, body: jenkinsBody(input, false), accessToken },
      jenkinsDto,
    ),
    toJenkins,
  );
}

export async function updateJenkins(accessToken: string, id: string, input: JenkinsInput) {
  return map(
    await callBackend(
      {
        method: "PUT",
        path: `${paths.jenkins}/${encodeURIComponent(id)}`,
        body: jenkinsBody(input, true),
        accessToken,
      },
      jenkinsDto,
    ),
    toJenkins,
  );
}

export async function createGitHub(accessToken: string, input: GitHubInput) {
  return map(
    await callBackend(
      { method: "POST", path: paths.github, body: githubBody(input, false), accessToken },
      githubDto,
    ),
    toGitHub,
  );
}

export async function updateGitHub(accessToken: string, id: string, input: GitHubInput) {
  return map(
    await callBackend(
      {
        method: "PUT",
        path: `${paths.github}/${encodeURIComponent(id)}`,
        body: githubBody(input, true),
        accessToken,
      },
      githubDto,
    ),
    toGitHub,
  );
}

export async function createSonarQube(accessToken: string, input: SonarQubeInput) {
  return map(
    await callBackend(
      { method: "POST", path: paths.sonarqube, body: sonarBody(input, false), accessToken },
      sonarDto,
    ),
    toSonar,
  );
}

export async function updateSonarQube(accessToken: string, id: string, input: SonarQubeInput) {
  return map(
    await callBackend(
      {
        method: "PUT",
        path: `${paths.sonarqube}/${encodeURIComponent(id)}`,
        body: sonarBody(input, true),
        accessToken,
      },
      sonarDto,
    ),
    toSonar,
  );
}

export async function deleteCredential(
  accessToken: string,
  tool: Tool,
  id: string,
): Promise<Result<null>> {
  return map(
    await callBackend(
      { method: "DELETE", path: `${paths[tool]}/${encodeURIComponent(id)}`, accessToken },
      z.object({ message: z.string() }),
    ),
    () => null,
  );
}

/** Makes [id] the tool's default credential (US-WEB-18). */
export async function setDefaultCredential(
  accessToken: string,
  tool: Tool,
  id: string,
): Promise<Result<null>> {
  return map(
    await callBackend(
      { method: "POST", path: `${paths[tool]}/switch/${encodeURIComponent(id)}`, accessToken },
      z.object({ _id: z.string() }),
    ),
    () => null,
  );
}
