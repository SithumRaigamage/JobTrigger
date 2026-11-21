"use client";

import Link from "next/link";
import { useActionState } from "react";

import { Field, Notice, SubmitButton } from "@/components/form";
import { routes } from "@/features/marketing/site-links";

import { requestToolAction, type RequestToolState } from "./actions";

const initial: RequestToolState = {};

/** US-WEB-04: the signed-in "Request a tool" form, filed as a ticket. */
export function RequestToolForm() {
  const [state, formAction, pending] = useActionState(requestToolAction, initial);

  if (state.sent) {
    return (
      <div className="flex flex-col gap-3 rounded-3xl bg-card p-7 shadow-lift sm:p-9">
        <h1 className="text-[1.625rem] font-extrabold tracking-[-0.02em]">Request sent</h1>
        <p>
          Ticket {state.sent.ticketId}. We reply to {state.sent.replyEmail}.
        </p>
        <Link href={routes.integrations}>Back to integrations</Link>
      </div>
    );
  }

  return (
    <form
      action={formAction}
      noValidate
      className="flex flex-col gap-4.5 rounded-3xl bg-card p-7 shadow-lift sm:p-9"
    >
      <h1 className="text-[1.625rem] font-extrabold tracking-[-0.02em]">Request a tool</h1>
      <p className="text-fg-secondary">
        Tell us which CI tool you use. Requests from the app and this page land in the same place.
      </p>
      {state.error && <Notice tone="error">{state.error}</Notice>}
      <Field
        id="subject"
        name="subject"
        label="Subject"
        required
        maxLength={120}
        defaultValue={state.subject ?? "Tool request: "}
      />
      <div className="flex flex-col gap-2">
        <label htmlFor="message" className="text-[0.8125rem] font-semibold text-fg-secondary">
          Details
        </label>
        <textarea
          id="message"
          name="message"
          required
          maxLength={4000}
          rows={6}
          defaultValue={state.message}
          placeholder="Which tool, and what you'd like to do with it. Don't paste tokens."
          className="rounded-control border border-line-strong bg-card px-3.5 py-3 text-base text-fg outline-none focus-visible:outline-2 focus-visible:outline-accent"
        />
      </div>
      <SubmitButton pending={pending}>{pending ? "Sending…" : "Send request"}</SubmitButton>
    </form>
  );
}
