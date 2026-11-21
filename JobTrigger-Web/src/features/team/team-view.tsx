import Link from "next/link";

import { Field } from "@/components/form";
import { Card } from "@/components/layout";
import type { Team, TeamState } from "@/domain/team";

import { routes } from "../marketing/site-links";

import {
  cancelInviteAction,
  createTeamAction,
  deleteTeamAction,
  inviteAction,
  leaveTeamAction,
  removeMemberAction,
  setSeatsAction,
  shareServerAction,
  unshareServerAction,
} from "./actions";
import { TeamForm } from "./team-forms";

/** One of the owner's own Jenkins servers, for sharing (AC10, AC12). */
export type ShareableServer = { id: string; serverName: string; jenkinsURL: string };

const dateFormat = new Intl.DateTimeFormat("en", { dateStyle: "long", timeZone: "UTC" });
const date = (iso: string | null) => (iso ? dateFormat.format(new Date(iso)) : null);

/**
 * US-SUB-11 AC12: the team page. Three states: the backend has teams off,
 * the user has no team yet, or their team (owner or member view).
 */
export function TeamView({ state, servers }: { state: TeamState; servers: ShareableServer[] }) {
  return (
    <>
      <p>
        <Link href={routes.account} className="text-sm">
          ← Account
        </Link>
      </p>
      <Card
        role="region"
        aria-labelledby="team-title"
        className="flex max-w-2xl flex-col gap-5 p-6"
      >
        <h1 id="team-title" className="text-[1.625rem] font-extrabold tracking-[-0.02em]">
          Team
        </h1>
        {!state.available && (
          <p data-testid="team-unavailable">
            Team plans aren&apos;t available yet. They&apos;re coming in JobTrigger 1.1.
          </p>
        )}
        {state.available && state.team === null && <NoTeam />}
        {state.available && state.team && state.team.role === "owner" && (
          <OwnerView team={state.team} servers={servers} />
        )}
        {state.available && state.team && state.team.role === "member" && (
          <MemberView team={state.team} />
        )}
      </Card>
    </>
  );
}

function NoTeam() {
  return (
    <>
      <p className="text-fg-secondary">
        Buy JobTrigger Pro for your team and share your Jenkins servers once. $6.99 per seat per
        month, from 2 seats. Start by naming the team; you choose the seats when you pay.
      </p>
      <TeamForm action={createTeamAction} label="Create team" pendingLabel="Creating…">
        <Field id="team-name" name="name" label="Team name" required maxLength={60} />
      </TeamForm>
    </>
  );
}

function Summary({ team }: { team: Team }) {
  const until = date(team.billing.periodEnd);
  return (
    <dl className="grid grid-cols-[auto_1fr] gap-x-6 gap-y-2 text-[0.9375rem]">
      <dt className="text-muted">Name</dt>
      <dd data-testid="team-name">{team.name}</dd>
      <dt className="text-muted">Seats</dt>
      <dd data-testid="team-seats">
        {team.seatsUsed} of {team.seats} used
      </dd>
      <dt className="text-muted">Plan</dt>
      <dd data-testid="team-plan">
        {team.active
          ? `Pro for everyone in the team${until ? `, ${team.billing.willRenew ? "renews" : "ends"} ${until}` : ""}`
          : "Not paid yet — members are on their own plan"}
      </dd>
    </dl>
  );
}

function OwnerView({ team, servers }: { team: Team; servers: ShareableServer[] }) {
  const shared = new Set(team.sharedServerIds);
  return (
    <>
      <Summary team={team} />
      {!team.active && (
        <p className="text-fg-secondary">
          <Link href="/account/billing">Buy Pro for the team</Link> to give everyone Pro.
        </p>
      )}

      <section aria-labelledby="members-title" className="flex flex-col gap-3">
        <h2 id="members-title" className="text-lg font-bold">
          Members
        </h2>
        <ul className="flex flex-col gap-2" data-testid="team-members">
          {team.members.map((member) => (
            <li key={member.userId} className="flex flex-wrap items-center justify-between gap-3">
              <span>
                {member.email ?? "Former member"}
                {member.owner && <span className="text-muted"> · owner</span>}
              </span>
              {!member.owner && (
                <TeamForm
                  action={removeMemberAction}
                  hidden={{ userId: member.userId }}
                  label="Remove"
                  tone="quiet"
                  confirm={`Remove ${member.email ?? "this member"} from the team?`}
                />
              )}
            </li>
          ))}
          {team.invites.map((invite) => (
            <li key={invite.id} className="flex flex-wrap items-center justify-between gap-3">
              <span>
                {invite.email}{" "}
                <span className="text-muted">· invited, until {date(invite.expiresAt)}</span>
              </span>
              <TeamForm
                action={cancelInviteAction}
                hidden={{ inviteId: invite.id }}
                label="Cancel invite"
                tone="quiet"
              />
            </li>
          ))}
        </ul>
        {team.seatsUsed < team.seats ? (
          <TeamForm action={inviteAction} label="Send invite" pendingLabel="Sending…">
            <Field id="invite-email" name="email" type="email" label="Invite by email" required />
          </TeamForm>
        ) : (
          <p className="text-sm text-muted">
            Every seat is taken. Add seats to invite someone else.
          </p>
        )}
      </section>

      <section aria-labelledby="seats-title" className="flex flex-col gap-3">
        <h2 id="seats-title" className="text-lg font-bold">
          Seats
        </h2>
        <TeamForm action={setSeatsAction} label="Change seats" tone="quiet">
          <Field
            id="team-seat-count"
            name="seats"
            type="number"
            label={`Seats (${team.prices.minSeats}–${team.prices.maxSeats})`}
            min={Math.max(team.prices.minSeats, team.seatsUsed)}
            max={team.prices.maxSeats}
            defaultValue={team.seats}
            required
          />
        </TeamForm>
      </section>

      <section aria-labelledby="shared-title" className="flex flex-col gap-3">
        <h2 id="shared-title" className="text-lg font-bold">
          Shared Jenkins servers
        </h2>
        <p className="text-sm text-muted">
          Members use these from the app without seeing your token. Stop sharing and access ends at
          once. GitHub and SonarQube tokens are personal and can&apos;t be shared.
        </p>
        {servers.length === 0 ? (
          <p className="text-fg-secondary">
            You have no Jenkins servers yet. <Link href="/servers/new">Add one</Link>.
          </p>
        ) : (
          <ul className="flex flex-col gap-2" data-testid="team-servers">
            {servers.map((server) => (
              <li key={server.id} className="flex flex-wrap items-center justify-between gap-3">
                <span>
                  {server.serverName} <span className="text-muted">· {server.jenkinsURL}</span>
                </span>
                {shared.has(server.id) ? (
                  <TeamForm
                    action={unshareServerAction}
                    hidden={{ credentialId: server.id }}
                    label="Stop sharing"
                    tone="quiet"
                  />
                ) : (
                  <TeamForm
                    action={shareServerAction}
                    hidden={{ credentialId: server.id }}
                    label="Share"
                    tone="quiet"
                  />
                )}
              </li>
            ))}
          </ul>
        )}
      </section>

      <TeamForm
        action={deleteTeamAction}
        label="Delete team"
        tone="quiet"
        confirm="Delete the team? Everyone goes back to their own plan."
      />
    </>
  );
}

function MemberView({ team }: { team: Team }) {
  const owner = team.members.find((member) => member.owner);
  return (
    <>
      <Summary team={team} />
      <p className="text-fg-secondary">
        {owner?.email ?? "The owner"} manages this team and its plan. Shared Jenkins servers appear
        in the app under Settings → Team servers.
      </p>
      <TeamForm
        action={leaveTeamAction}
        label="Leave team"
        tone="quiet"
        confirm="Leave the team? You go back to your own plan."
      />
    </>
  );
}
