"use client";

import { useActionState } from "react";

import { Notice, SubmitButton } from "@/components/form";

import { approveStudentAction, rejectStudentAction, type ReviewState } from "./actions";

/** Approve and reject, for one pending document application. */
export function ReviewForms({ id }: { id: string }) {
  const [approveState, approve, approving] = useActionState(
    approveStudentAction,
    {} as ReviewState,
  );
  const [rejectState, reject, rejecting] = useActionState(rejectStudentAction, {} as ReviewState);

  return (
    <div className="flex flex-wrap items-start gap-5">
      <form
        action={approve}
        className="flex min-w-0 flex-[1_1_260px] flex-col gap-3 rounded-card border border-line p-5"
      >
        <h3 className="font-bold">Approve</h3>
        <p className="text-sm text-muted">Gives the student Pro for 365 days.</p>
        {approveState.error && <Notice tone="error">{approveState.error}</Notice>}
        <input type="hidden" name="id" value={id} />
        <SubmitButton pending={approving}>Approve</SubmitButton>
      </form>
      <form
        action={reject}
        className="flex min-w-0 flex-[1_1_320px] flex-col gap-3 rounded-card border border-line p-5"
      >
        <h3 className="font-bold">Reject</h3>
        {rejectState.error && <Notice tone="error">{rejectState.error}</Notice>}
        <input type="hidden" name="id" value={id} />
        <label htmlFor="reject-reason" className="text-[0.8125rem] font-semibold text-fg-secondary">
          Reason (the student sees this)
        </label>
        <textarea
          id="reject-reason"
          name="reason"
          rows={3}
          maxLength={500}
          required
          className="rounded-control border border-line-strong bg-card p-3 text-base text-fg"
        />
        <SubmitButton pending={rejecting}>Reject</SubmitButton>
      </form>
    </div>
  );
}
