"use client";

import {
  useActionState,
  useEffect,
  useRef,
  useState,
  startTransition,
  type ChangeEvent,
  type FormEvent,
} from "react";

import { Card } from "@/components/layout";
import { Field, Notice, SubmitButton } from "@/components/form";
import {
  AREA_LABELS,
  CATEGORY_LABELS,
  IMPACT_LABELS,
  MAX_SCREENSHOTS,
  SCREENSHOT_ACCEPT,
  SUPPORT_AREAS,
  SUPPORT_CATEGORIES,
  SUPPORT_IMPACTS,
} from "@/domain/support";

import { submitSupportAction, type SupportFormState } from "./actions";

const initial: SupportFormState = {};

const chip =
  "inline-flex items-center gap-2 rounded-full border border-line-strong px-3 py-1.5 text-sm font-semibold";

/**
 * US-SUP-05/06: the signed-in report form. The files stay in client state
 * until submit, so previews and remove work without another backend call;
 * the action gets them in one FormData and repeats every limit and byte check.
 */
export function SupportForm({ replyEmail }: { replyEmail: string }) {
  const [state, dispatch, pending] = useActionState(submitSupportAction, initial);
  const [files, setFiles] = useState<File[]>([]);
  const [previews, setPreviews] = useState<string[]>([]);
  const [pickError, setPickError] = useState<string | null>(null);
  const livePreviews = useRef<string[]>([]);

  // Blob URLs are created in the pick handler (an event, not an effect). Keep
  // the current list in a ref so the unmount cleanup can release what's live;
  // a removed one is released when it's removed.
  useEffect(() => {
    livePreviews.current = previews;
  }, [previews]);
  useEffect(
    () => () => {
      if (typeof URL.revokeObjectURL === "function") {
        for (const url of livePreviews.current) if (url) URL.revokeObjectURL(url);
      }
    },
    [],
  );

  if (state.sent) {
    return (
      <Card radius="panel" id="send-report" className="p-7 sm:p-9">
        <h2 className="text-[1.375rem] font-extrabold tracking-[-0.02em]">Report sent</h2>
        <p className="mt-2">
          Ticket {state.sent.ticketId}. We reply to {state.sent.replyEmail}.
        </p>
      </Card>
    );
  }

  function onPick(event: ChangeEvent<HTMLInputElement>) {
    const chosen = Array.from(event.target.files ?? []);
    event.target.value = ""; // the same file can be picked again after a remove
    if (chosen.length === 0) return;
    if (files.length + chosen.length > MAX_SCREENSHOTS) {
      setPickError(`Attach at most ${MAX_SCREENSHOTS} screenshots.`);
      return;
    }
    const urls = chosen.map((file) =>
      typeof URL.createObjectURL === "function" ? URL.createObjectURL(file) : "",
    );
    setPreviews([...previews, ...urls]);
    setFiles([...files, ...chosen]);
    setPickError(null);
  }

  function remove(index: number) {
    const url = previews[index];
    if (url && typeof URL.revokeObjectURL === "function") URL.revokeObjectURL(url);
    setPreviews(previews.filter((_, position) => position !== index));
    setFiles(files.filter((_, position) => position !== index));
    setPickError(null);
  }

  function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    // The native input is deliberately unnamed: the client-held files are
    // the single source of truth, so a removed one can never slip through.
    for (const file of files) data.append("screenshots", file);
    startTransition(() => dispatch(data));
  }

  return (
    <form
      onSubmit={onSubmit}
      noValidate
      id="send-report"
      className="flex flex-col gap-5 rounded-3xl bg-card p-7 shadow-lift sm:p-9"
    >
      <div className="flex flex-col gap-1.5">
        <h2 className="text-[1.375rem] font-extrabold tracking-[-0.02em]">Send a report</h2>
        <p className="text-sm text-fg-secondary">
          Signed in as {replyEmail}. We reply to this address, and never ask for a token or
          password.
        </p>
      </div>
      {state.error && <Notice tone="error">{state.error}</Notice>}

      <fieldset className="flex flex-col gap-2.5">
        <legend className="text-[0.8125rem] font-semibold text-fg-secondary">
          What kind of report?
        </legend>
        <div className="flex flex-wrap gap-2">
          {SUPPORT_CATEGORIES.map((wire) => (
            <label key={wire} className={chip}>
              <input
                type="radio"
                name="category"
                value={wire}
                defaultChecked={wire === (state.category || "bug")}
              />
              {CATEGORY_LABELS[wire]}
            </label>
          ))}
        </div>
      </fieldset>

      <fieldset className="flex flex-col gap-2.5">
        <legend className="text-[0.8125rem] font-semibold text-fg-secondary">
          Affected areas <span className="font-normal text-muted">(optional)</span>
        </legend>
        <div className="flex flex-wrap gap-2">
          {SUPPORT_AREAS.map((wire) => (
            <label key={wire} className={chip}>
              <input
                type="checkbox"
                name="areas"
                value={wire}
                defaultChecked={state.areas?.includes(wire) ?? false}
              />
              {AREA_LABELS[wire]}
            </label>
          ))}
        </div>
      </fieldset>

      <div className="flex flex-col gap-2">
        <label
          htmlFor="support-impact"
          className="text-[0.8125rem] font-semibold text-fg-secondary"
        >
          Impact
        </label>
        <select
          id="support-impact"
          name="impact"
          defaultValue={state.impact || "minor"}
          className="h-12.5 rounded-control border border-line-strong bg-card px-3.5 text-base text-fg outline-none focus-visible:outline-2 focus-visible:outline-accent"
        >
          {SUPPORT_IMPACTS.map((wire) => (
            <option key={wire} value={wire}>
              {IMPACT_LABELS[wire]}
            </option>
          ))}
        </select>
      </div>

      <Field
        id="support-subject"
        name="subject"
        label="Subject"
        required
        maxLength={120}
        defaultValue={state.subject ?? ""}
        placeholder="Build log is blank for long jobs"
      />
      <div className="flex flex-col gap-2">
        <label
          htmlFor="support-message"
          className="text-[0.8125rem] font-semibold text-fg-secondary"
        >
          Details
        </label>
        <textarea
          id="support-message"
          name="message"
          required
          maxLength={4000}
          rows={6}
          defaultValue={state.message}
          placeholder="What happened, what you expected, and what you tried."
          className="rounded-control border border-line-strong bg-card px-3.5 py-3 text-base text-fg outline-none focus-visible:outline-2 focus-visible:outline-accent"
        />
      </div>

      <div className="flex flex-col gap-2.5">
        <label
          htmlFor="support-screenshots"
          className="text-[0.8125rem] font-semibold text-fg-secondary"
        >
          Screenshots <span className="font-normal text-muted">(optional)</span>
        </label>
        <p className="text-sm text-muted">
          Blur tokens, passwords and personal data before sending. JPG or PNG, up to{" "}
          {MAX_SCREENSHOTS} files of 5 MB each.
        </p>
        <input
          id="support-screenshots"
          type="file"
          accept={SCREENSHOT_ACCEPT}
          multiple
          onChange={onPick}
          disabled={pending || files.length >= MAX_SCREENSHOTS}
          className="text-sm text-fg-secondary file:mr-3 file:rounded-control file:border-0 file:bg-raised file:px-3 file:py-2 file:font-semibold file:text-fg"
        />
        {pickError && <Notice tone="error">{pickError}</Notice>}
        {files.length > 0 && (
          <ul className="flex flex-wrap gap-3">
            {files.map((file, index) => (
              <li key={`${file.name}-${index}`} className="flex flex-col items-center gap-1">
                {previews[index] ? (
                  // The route to our own origin is checked by the CSP; these
                  // are local blob URLs, so no backend bytes reach the page.
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={previews[index]}
                    alt={`Preview of ${file.name}`}
                    className="size-20 rounded-control border border-line object-cover"
                  />
                ) : (
                  <span className="flex size-20 items-center justify-center rounded-control border border-line text-xs text-muted">
                    Image
                  </span>
                )}
                <button
                  type="button"
                  onClick={() => remove(index)}
                  className="text-xs font-semibold text-failed-fg"
                >
                  Remove {file.name}
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>

      <SubmitButton pending={pending}>{pending ? "Sending…" : "Send report"}</SubmitButton>
    </form>
  );
}
