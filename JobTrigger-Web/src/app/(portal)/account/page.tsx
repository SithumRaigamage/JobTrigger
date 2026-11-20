import type { Metadata } from "next";

import { BILLING_PATH, getPaddleConfig } from "@/billing/paddle-config";
import { AccountView } from "@/features/account/account-view";
import { requireSession } from "@/server/guard";
import { studentAt } from "@/domain/student";
import { getStudent } from "@/server/student-api";
import { getSubscription } from "@/server/subscription-api";
import { getTeam } from "@/server/team-api";

export const metadata: Metadata = { title: "Account" };

export default async function AccountPage() {
  const session = await requireSession();
  // Best effort: the plan card is extra, so an unreachable backend, an old
  // backend with no /api/subscription, or billing being off just leaves it
  // out. The proxy has renewed the token already, as on the servers page.
  const result = await getSubscription(session.accessToken);
  const subscription = result.ok && result.value.billingEnabled ? result.value : null;
  // Phase 21: the student plan, only where billing is on and the account is
  // on Free or already a student. Also best effort.
  const eligible =
    subscription !== null && (subscription.plan === "free" || subscription.source === "student");
  const student = eligible ? await getStudent(session.accessToken) : null;
  // US-SUB-11: the team card, only while the backend has teams on.
  const team = await getTeam(session.accessToken);
  const teamName = team.ok && team.value.available ? (team.value.team?.name ?? null) : undefined;
  return (
    <AccountView
      email={session.email}
      subscription={subscription}
      student={student?.ok ? studentAt(student.value, new Date()) : null}
      billingHref={getPaddleConfig() ? BILLING_PATH : null}
      teamName={teamName}
    />
  );
}
