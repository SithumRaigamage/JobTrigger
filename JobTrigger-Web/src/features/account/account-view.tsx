import Link from "next/link";

import { Card } from "@/components/layout";
import type { StudentApplication } from "@/domain/student";
import type { Subscription } from "@/domain/subscription";
import { StudentCard } from "@/features/student/student-card";

import { ChangePassword, DeleteAccount, SignOutEverywhere } from "./account-forms";
import { deleteNotice, PlanSection } from "./plan-section";

/** Account (design 14; US-WEB-20, 21). */
export function AccountView({
  email,
  subscription = null,
  student = null,
  billingHref = null,
  teamName,
}: {
  email: string;
  /** Null: billing is off or the plan couldn't be read, so no plan card. */
  subscription?: Subscription | null;
  /** Phase 21: the student application; null hides the student card. */
  student?: StudentApplication | null;
  /** Set when web checkout is set up (P20-83). */
  billingHref?: string | null;
  /**
   * US-SUB-11: undefined hides the team card (teams off); null offers to
   * create one; a name links to it.
   */
  teamName?: string | null;
}) {
  return (
    <>
      <section
        data-surface="dark"
        className="relative flex flex-wrap items-center gap-4.5 overflow-hidden rounded-3xl p-7"
      >
        <div
          aria-hidden="true"
          className="absolute -top-15 -right-10 size-55 rounded-full border-32 border-accent/35"
        />
        <span
          aria-hidden="true"
          className="relative flex size-16 items-center justify-center rounded-full bg-accent text-[1.625rem] font-extrabold text-on-accent"
        >
          {email.charAt(0).toUpperCase()}
        </span>
        <div className="relative flex min-w-0 flex-col gap-1">
          <h1 className="text-[1.625rem] font-extrabold tracking-[-0.02em]">Account</h1>
          <span className="truncate font-mono text-sm text-fg-secondary">{email}</span>
        </div>
      </section>
      <div className="flex flex-wrap items-start gap-5">
        <ChangePassword />
        {subscription && <PlanSection subscription={subscription} billingHref={billingHref} />}
        {subscription && student && <StudentCard application={student} />}
        {teamName !== undefined && (
          <Card data-testid="team-card" className="flex flex-[1_1_320px] flex-col gap-3 p-6">
            <h2 className="text-lg font-bold">Team</h2>
            <p className="text-fg-secondary">
              {teamName === null
                ? "Buy Pro for your team and share your Jenkins servers once."
                : `You're in ${teamName}.`}
            </p>
            <Link href="/account/team" className="self-start font-semibold">
              {teamName === null ? "Set up a team →" : "Open the team →"}
            </Link>
          </Card>
        )}
        <div className="flex min-w-0 flex-[1_1_320px] flex-col gap-5">
          <SignOutEverywhere />
          <DeleteAccount
            email={email}
            subscriptionNotice={subscription ? deleteNotice(subscription) : null}
          />
        </div>
      </div>
    </>
  );
}
