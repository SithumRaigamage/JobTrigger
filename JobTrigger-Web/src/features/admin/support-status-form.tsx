"use client";

import { useActionState } from "react";

import { Notice, SubmitButton } from "@/components/form";
import { STATUS_LABELS, SUPPORT_STATUSES, type SupportStatus } from "@/domain/support";

import { updateSupportStatusAction, type SupportStatusState } from "./actions";

/** US-SUP-07: the existing status control, now on a support ticket. */
export function SupportStatusForm({ id, status }: { id: string; status: string }) {
  const [state, action, pending] = useActionState(
    updateSupportStatusAction,
    {} as SupportStatusState,
  );

  return (
    <form action={action} className="flex flex-col gap-3 rounded-card border border-line p-5">
      <h3 className="font-bold">Triage</h3>
      {state.error && <Notice tone="error">{state.error}</Notice>}
      {state.notice && <Notice tone="info">{state.notice}</Notice>}
      <input type="hidden" name="id" value={id} />
      <label htmlFor="support-status" className="text-[0.8125rem] font-semibold text-fg-secondary">
        Status
      </label>
      <select
        id="support-status"
        name="status"
        defaultValue={status}
        className="h-12 rounded-control border border-line-strong bg-card px-3.5 text-base text-fg"
      >
        {SUPPORT_STATUSES.map((wire: SupportStatus) => (
          <option key={wire} value={wire}>
            {STATUS_LABELS[wire]}
          </option>
        ))}
      </select>
      <SubmitButton pending={pending}>{pending ? "Saving…" : "Save status"}</SubmitButton>
    </form>
  );
}
