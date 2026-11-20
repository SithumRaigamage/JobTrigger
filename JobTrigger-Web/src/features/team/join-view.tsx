import Link from "next/link";

import { Card } from "@/components/layout";

import { routes } from "../marketing/site-links";

import { joinTeamAction } from "./actions";
import { TeamForm } from "./team-forms";

/**
 * US-SUB-11 AC14: accept an invite. Each refusal (expired, another email,
 * already in a team, full) comes back from the backend in plain words.
 */
export function JoinView({ email, token }: { email: string; token: string | null }) {
  return (
    <>
      <p>
        <Link href={routes.account} className="text-sm">
          ← Account
        </Link>
      </p>
      <Card role="region" aria-labelledby="join-title" className="flex max-w-xl flex-col gap-4 p-6">
        <h1 id="join-title" className="text-[1.625rem] font-extrabold tracking-[-0.02em]">
          Join a team
        </h1>
        {token === null ? (
          <p data-testid="join-no-token">
            This invite link isn&apos;t complete. Open it again from the email.
          </p>
        ) : (
          <>
            <p className="text-fg-secondary">
              You&apos;re signed in as <strong className="text-fg">{email}</strong>. Joining gives
              you JobTrigger Pro and the Jenkins servers the team shares.
            </p>
            <TeamForm
              action={joinTeamAction}
              hidden={{ token }}
              label="Join the team"
              pendingLabel="Joining…"
            />
          </>
        )}
      </Card>
    </>
  );
}
