"use client";

import { useActionState } from "react";

import { Notice, SubmitButton } from "@/components/form";

import { grantPlanAction, revokePlanAction, type PlanActionState } from "./subscription-actions";

/** Grant Pro (bounded or open-ended) and revoke the grant, for one account. */
export function PlanAdminForms({ userId }: { userId: string }) {
  const [grantState, grant, granting] = useActionState(grantPlanAction, {} as PlanActionState);
  const [revokeState, revoke, revoking] = useActionState(revokePlanAction, {} as PlanActionState);
  const daysId = `days-${userId}`;

  return (
    <div className="flex flex-wrap items-end gap-4">
      <form action={grant} className="flex flex-wrap items-end gap-2">
        <input type="hidden" name="id" value={userId} />
        <label htmlFor={daysId} className="flex flex-col gap-1 text-xs font-semibold text-muted">
          Days (empty = no end)
          <input
            id={daysId}
            name="days"
            type="number"
            min={1}
            max={3650}
            inputMode="numeric"
            placeholder="30"
            className="h-10 w-28 rounded-control border border-line-strong bg-card px-3 text-sm text-fg"
          />
        </label>
        <SubmitButton pending={granting}>Grant Pro</SubmitButton>
      </form>
      <form action={revoke}>
        <input type="hidden" name="id" value={userId} />
        <SubmitButton pending={revoking}>Revoke grant</SubmitButton>
      </form>
      {grantState.error && <Notice tone="error">{grantState.error}</Notice>}
      {revokeState.error && <Notice tone="error">{revokeState.error}</Notice>}
    </div>
  );
}
