"use client";

import { useActionState, useRef } from "react";

import type { ActionState } from "./actions";

/**
 * "Delete this server" card and its confirmation (design 12; US-WEB-15).
 * A native <dialog>: modal, focus-trapped, Esc closes it. Delete is
 * destructive-styled and never the default button.
 */
export function DeleteServer({
  name,
  toolName,
  action,
}: {
  name: string;
  toolName: string;
  action: (state: ActionState) => Promise<ActionState>;
}) {
  const dialog = useRef<HTMLDialogElement>(null);
  const [state, formAction, pending] = useActionState(action, {});

  return (
    <div className="flex flex-col gap-3 rounded-panel border border-failed-fg/40 bg-card p-5.5">
      <h2 className="font-bold text-failed-fg">Delete this server</h2>
      <p className="text-sm leading-normal text-muted">
        It disappears from the app on every device. {toolName} itself isn&apos;t touched.
      </p>
      <button
        type="button"
        onClick={() => dialog.current?.showModal()}
        className="h-11 self-start rounded-control border border-failed-fg bg-card px-4 text-sm font-semibold text-failed-fg hover:bg-failed-bg"
      >
        Delete server
      </button>
      {state.error && (
        <p role="alert" className="text-sm font-semibold text-failed-fg">
          {state.error}
        </p>
      )}

      <dialog
        ref={dialog}
        aria-labelledby="delete-heading"
        aria-describedby="delete-description"
        className="m-auto w-[min(440px,calc(100vw-40px))] rounded-panel bg-card p-7 text-fg backdrop:bg-scrim"
      >
        <form action={formAction} className="flex flex-col gap-4">
          <h2 id="delete-heading" className="text-xl font-extrabold">
            Delete “{name}”?
          </h2>
          <p id="delete-description" className="text-sm leading-normal text-muted">
            It disappears from the app on every device. This can&apos;t be undone.
          </p>
          <div className="flex flex-wrap justify-end gap-2.5">
            {/* Cancel first and focused by default: delete is never the default. */}
            <button
              type="button"
              autoFocus
              onClick={() => dialog.current?.close()}
              className="h-11 rounded-control border border-line-strong bg-card px-4 text-sm font-semibold text-fg hover:bg-raised"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={pending}
              className="h-11 rounded-control bg-failed-fg px-4 text-sm font-bold text-on-accent disabled:opacity-70"
            >
              {pending ? "Deleting…" : "Delete server"}
            </button>
          </div>
        </form>
      </dialog>
    </div>
  );
}
