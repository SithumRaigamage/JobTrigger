"use client";

import { useState, useTransition } from "react";

import type { RevealState } from "./actions";

/** The saved token's mask with an eye that fetches and shows it on tap. */
export function RevealToken({
  mask,
  action,
}: {
  mask: string;
  action: () => Promise<RevealState>;
}) {
  const [secret, setSecret] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();
  const [copied, setCopied] = useState(false);
  const visible = secret !== null;

  function toggle() {
    if (visible) {
      setSecret(null);
      return;
    }
    setError(null);
    startTransition(async () => {
      const result = await action();
      if (result.secret) setSecret(result.secret);
      else setError(result.error ?? "Couldn't show the token.");
    });
  }

  function copy() {
    setError(null);
    startTransition(async () => {
      let value = secret;
      if (value === null) {
        const result = await action();
        if (!result.secret) {
          setError(result.error ?? "Couldn't copy the token.");
          return;
        }
        value = result.secret;
      }
      try {
        await navigator.clipboard.writeText(value);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
      } catch {
        setError("Couldn't copy. Show the token and copy it by hand.");
      }
    });
  }

  return (
    <>
      <div className="flex items-center gap-1">
        <span
          data-testid="saved-token"
          className="min-w-0 flex-1 font-mono text-[0.9375rem] break-all"
        >
          {visible ? secret : mask}
        </span>
        <button
          type="button"
          aria-label={`${visible ? "Hide" : "Show"} saved token`}
          aria-pressed={visible}
          disabled={pending}
          onClick={toggle}
          className="flex size-11 shrink-0 items-center justify-center text-fg-secondary hover:text-fg disabled:opacity-60"
        >
          <svg
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.8"
            aria-hidden="true"
          >
            <path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z" />
            <circle cx="12" cy="12" r="3" />
            {visible && <path d="M3 3l18 18" />}
          </svg>
        </button>
        <button
          type="button"
          aria-label="Copy saved token"
          disabled={pending}
          onClick={copy}
          className="flex h-11 shrink-0 items-center justify-center px-2 text-[0.8125rem] font-semibold text-fg-secondary hover:text-fg disabled:opacity-60"
        >
          {copied ? "Copied" : "Copy"}
        </button>
      </div>
      {error && (
        <span role="alert" className="text-failed-fg">
          {error}
        </span>
      )}
    </>
  );
}
