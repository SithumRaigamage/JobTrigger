"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import { failureMessage } from "@/domain/app-failure";
import type { Result } from "@/domain/result";
import { authed } from "@/server/authed";
import { requireSession } from "@/server/guard";
import {
  cancelInvite,
  createTeam,
  deleteTeam,
  inviteMember,
  joinTeam,
  leaveTeam,
  removeMember,
  setSeats,
  shareServer,
  teamCheckout,
  unshareServer,
} from "@/server/team-api";

/*
 * US-SUB-11 (AC12–AC14). Every action checks the session itself (the proxy
 * skips prefetches), validates what the form sent, and only forwards: who
 * may do what is decided by the backend.
 */

export type TeamActionState = { error?: string; done?: string };

const TEAM_PATH = "/account/team";
const id = z.string().regex(/^[A-Za-z0-9]{1,64}$/);
const seats = z.coerce.number().int().min(2).max(100);

/** Runs [call] for the signed-in user; refreshes the team page on success. */
async function run<T>(
  call: (token: string) => Promise<Result<T>>,
  done?: string,
): Promise<TeamActionState> {
  const session = await requireSession();
  const result = await authed(session, call);
  if (!result.ok) return { error: failureMessage(result.failure) };
  revalidatePath(TEAM_PATH);
  return done ? { done } : {};
}

export async function createTeamAction(
  _: TeamActionState,
  form: FormData,
): Promise<TeamActionState> {
  const name = z.string().trim().min(1).max(60).safeParse(form.get("name"));
  if (!name.success) return { error: "Give the team a name of 1 to 60 characters." };
  return run((token) => createTeam(token, name.data));
}

export async function inviteAction(_: TeamActionState, form: FormData): Promise<TeamActionState> {
  const email = z
    .email()
    .max(254)
    .safeParse(String(form.get("email") ?? "").trim());
  if (!email.success) return { error: "Enter an email address." };
  return run((token) => inviteMember(token, email.data), `Invite sent to ${email.data}.`);
}

export async function cancelInviteAction(
  _: TeamActionState,
  form: FormData,
): Promise<TeamActionState> {
  const parsed = id.safeParse(form.get("inviteId"));
  if (!parsed.success) return { error: "That invite couldn't be found." };
  return run((token) => cancelInvite(token, parsed.data));
}

export async function removeMemberAction(
  _: TeamActionState,
  form: FormData,
): Promise<TeamActionState> {
  const parsed = id.safeParse(form.get("userId"));
  if (!parsed.success) return { error: "That person couldn't be found." };
  return run((token) => removeMember(token, parsed.data));
}

export async function leaveTeamAction(_: TeamActionState): Promise<TeamActionState> {
  return run((token) => leaveTeam(token), "You left the team.");
}

export async function deleteTeamAction(_: TeamActionState): Promise<TeamActionState> {
  return run((token) => deleteTeam(token), "The team was deleted.");
}

export async function setSeatsAction(_: TeamActionState, form: FormData): Promise<TeamActionState> {
  const parsed = seats.safeParse(form.get("seats"));
  if (!parsed.success) return { error: "Choose 2 to 100 seats." };
  return run((token) => setSeats(token, parsed.data), `The team now has ${parsed.data} seats.`);
}

export async function shareServerAction(
  _: TeamActionState,
  form: FormData,
): Promise<TeamActionState> {
  const parsed = id.safeParse(form.get("credentialId"));
  if (!parsed.success) return { error: "Choose one of your Jenkins servers." };
  return run((token) => shareServer(token, parsed.data));
}

export async function unshareServerAction(
  _: TeamActionState,
  form: FormData,
): Promise<TeamActionState> {
  const parsed = id.safeParse(form.get("credentialId"));
  if (!parsed.success) return { error: "That server couldn't be found." };
  return run((token) => unshareServer(token, parsed.data));
}

/** AC14: accepts an invite, then shows the team. */
export async function joinTeamAction(_: TeamActionState, form: FormData): Promise<TeamActionState> {
  const token = z.string().min(20).max(100).safeParse(form.get("token"));
  if (!token.success) return { error: "This invite link isn't valid." };
  const state = await run((accessToken) => joinTeam(accessToken, token.data));
  if (state.error) return state;
  redirect(TEAM_PATH);
}

export type TeamCheckoutState =
  { error: string } | { transactionId: string; environment: "sandbox" | "production" };

/** AC13: the transaction the billing page opens with Paddle.js. */
export async function startTeamCheckoutAction(
  period: string,
  seatCount: number,
): Promise<TeamCheckoutState> {
  const session = await requireSession();
  const chosen = z.enum(["monthly", "yearly"]).safeParse(period);
  const count = seats.safeParse(seatCount);
  if (!chosen.success) return { error: "Choose monthly or yearly." };
  if (!count.success) return { error: "Choose 2 to 100 seats." };
  const result = await authed(session, (token) => teamCheckout(token, chosen.data, count.data));
  if (!result.ok) return { error: failureMessage(result.failure) };
  return result.value;
}
