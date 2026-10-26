import "server-only";

import type { Credential } from "@/domain/credentials";
import { fail, ok, type Result } from "@/domain/result";
import { listGitHub, listJenkins, listSonarQube } from "@/server/credentials-api";

/**
 * Every saved server and account, Jenkins first (US-WEB-11), or the first
 * failure. Read-only: a page render can't save a refreshed session, so a
 * 401 here means the session really has ended.
 */
export async function loadServers(accessToken: string): Promise<Result<Credential[]>> {
  const [jenkins, github, sonarqube] = await Promise.all([
    listJenkins(accessToken),
    listGitHub(accessToken),
    listSonarQube(accessToken),
  ]);
  for (const result of [jenkins, github, sonarqube]) if (!result.ok) return fail(result.failure);
  return ok([
    ...(jenkins.ok ? jenkins.value : []),
    ...(github.ok ? github.value : []),
    ...(sonarqube.ok ? sonarqube.value : []),
  ]);
}
