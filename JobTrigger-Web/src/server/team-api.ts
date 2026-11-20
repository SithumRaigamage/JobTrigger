import "server-only";

import { z } from "zod";

import { ok, type Result } from "@/domain/result";
import type { Team, TeamPeriod, TeamState } from "@/domain/team";

import { callBackend, type BackendCall } from "./backend-client";

/*
 * US-SUB-11: /api/team (docs/api-reference.md "Team plan"). Every refusal
 * the backend explains (403/404/409/410 with a sentence) is shown as-is: the
 * messages are written for users (AUD-06).
 */

const team = z.object({
  id: z.string(),
  name: z.string(),
  role: z.enum(["owner", "member"]),
  seats: z.number().int(),
  seatsUsed: z.number().int(),
  active: z.boolean(),
  billing: z.object({
    status: z.string(),
    period: z.enum(["monthly", "yearly"]).nullable().catch(null),
    periodEnd: z.string().nullable(),
    willRenew: z.boolean(),
  }),
  members: z.array(
    z.object({
      userId: z.string(),
      email: z.string().nullable(),
      owner: z.boolean(),
      joinedAt: z.string(),
    }),
  ),
  invites: z.array(z.object({ id: z.string(), email: z.string(), expiresAt: z.string() })),
  sharedServerIds: z.array(z.string()),
  prices: z.object({
    monthly: z.number(),
    yearly: z.number(),
    minSeats: z.number().int(),
    maxSeats: z.number().int(),
  }),
}) satisfies z.ZodType<Team>;

const teamOrNull = team.nullable();
const message = z.object({ message: z.string() });

/** Refusals that carry the backend's own sentence. */
const EXPLAIN = { explain: true, explainStatuses: [403, 404, 410] } as const;

function call<S extends z.ZodType>(
  accessToken: string,
  request: Omit<BackendCall, "accessToken">,
  schema: S,
): Promise<Result<z.infer<S>>> {
  return callBackend({ ...EXPLAIN, ...request, accessToken }, schema);
}

/** AC12: my team, none, or teams switched off (a plain 404). */
export async function getTeam(accessToken: string): Promise<Result<TeamState>> {
  const result = await callBackend({ path: "/api/team", accessToken }, teamOrNull);
  if (result.ok) return ok({ available: true, team: result.value });
  if (result.failure.kind === "notFound") return ok({ available: false });
  return result;
}

export const createTeam = (accessToken: string, name: string): Promise<Result<Team>> =>
  call(accessToken, { method: "POST", path: "/api/team", body: { name } }, team);

export const deleteTeam = (accessToken: string) =>
  call(accessToken, { method: "DELETE", path: "/api/team" }, message);

export const inviteMember = (accessToken: string, email: string) =>
  call(accessToken, { method: "POST", path: "/api/team/invites", body: { email } }, team);

export const cancelInvite = (accessToken: string, inviteId: string) =>
  call(
    accessToken,
    { method: "DELETE", path: `/api/team/invites/${encodeURIComponent(inviteId)}` },
    team,
  );

export const joinTeam = (accessToken: string, token: string) =>
  call(accessToken, { method: "POST", path: "/api/team/join", body: { token } }, team);

export const removeMember = (accessToken: string, userId: string) =>
  call(
    accessToken,
    { method: "DELETE", path: `/api/team/members/${encodeURIComponent(userId)}` },
    team,
  );

export const leaveTeam = (accessToken: string) =>
  call(accessToken, { method: "POST", path: "/api/team/leave" }, message);

export const setSeats = (accessToken: string, seats: number) =>
  call(accessToken, { method: "PUT", path: "/api/team/seats", body: { seats } }, team);

const checkout = z.object({
  transactionId: z.string().min(1),
  environment: z.enum(["sandbox", "production"]),
});

/** AC13: a Paddle transaction for the team's seats. */
export const teamCheckout = (accessToken: string, period: TeamPeriod, seats: number) =>
  call(
    accessToken,
    { method: "POST", path: "/api/team/checkout", body: { period, seats } },
    checkout,
  );

export const shareServer = (accessToken: string, credentialId: string) =>
  call(accessToken, { method: "POST", path: "/api/team/servers", body: { credentialId } }, team);

export const unshareServer = (accessToken: string, credentialId: string) =>
  call(
    accessToken,
    { method: "DELETE", path: `/api/team/servers/${encodeURIComponent(credentialId)}` },
    team,
  );
