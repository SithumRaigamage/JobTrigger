"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { failureMessage } from "@/domain/app-failure";
import { authed } from "@/server/authed";
import {
  grantAdminPlan,
  isAdminSubscriptionId,
  revokeAdminPlan,
} from "@/server/admin-subscriptions-api";
import { requireSession } from "@/server/guard";

/*
 * Release 1.0.0: grant or revoke a tester's Pro from the owner console.
 * The backend checks the super-admin role on every call, and the id is
 * checked for shape before it is built into a path. Only the grant source
 * is affected; a paid store or web subscription is never cancelled here.
 */

export type PlanActionState = { error?: string };

const MAX_DAYS = 3650;

export async function grantPlanAction(
  _previous: PlanActionState,
  form: FormData,
): Promise<PlanActionState> {
  const session = await requireSession();
  const id = String(form.get("id") ?? "");
  if (!isAdminSubscriptionId(id)) return { error: "That account couldn't be found." };

  const raw = String(form.get("days") ?? "").trim();
  const days = raw === "" ? null : Number(raw);
  if (days !== null && (!Number.isInteger(days) || days < 1 || days > MAX_DAYS)) {
    return { error: `Days must be a whole number from 1 to ${MAX_DAYS}, or empty for no end.` };
  }

  const result = await authed(session, (token) => grantAdminPlan(token, id, days));
  if (!result.ok) return { error: failureMessage(result.failure) };
  revalidatePath("/admin/subscriptions");
  redirect("/admin/subscriptions?notice=granted");
}

export async function revokePlanAction(
  _previous: PlanActionState,
  form: FormData,
): Promise<PlanActionState> {
  const session = await requireSession();
  const id = String(form.get("id") ?? "");
  if (!isAdminSubscriptionId(id)) return { error: "That account couldn't be found." };

  const result = await authed(session, (token) => revokeAdminPlan(token, id));
  if (!result.ok) return { error: failureMessage(result.failure) };
  revalidatePath("/admin/subscriptions");
  redirect("/admin/subscriptions?notice=revoked");
}
