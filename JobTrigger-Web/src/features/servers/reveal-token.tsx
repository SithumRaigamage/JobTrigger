"use client";

import { useState, useTransition } from "react";

import type { RevealState } from "./actions";

type Ask = "show" | "copy";

/**
 * The saved token's mask with an eye that shows it and a button that copies
 * it. Either one first asks for the account password: [action] gets it, and
 * a wrong password comes back as an error with nothing revealed.
 */
export function RevealToken({
  mask,
  action,
}: {
  mask: string;
  action: (password: string) => Promise<RevealState>;
}) {
  const [secret, setSecret] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [ask, setAsk] = useState<Ask | null>(null);
  const [password, setPassword] = useState("");
  const [pending, startTransition] = useTransition();
  const [copied, setCopied] = useState(false);
  const visible = secret !== null;

  function toggle() {
    setError(null);
    if (visible) {
      setSecret(null);
      return;
    }
    setAsk("show");
  }

  function submit(event: React.FormEvent) {
    event.preventDefault();
    const purpose = ask;
    const typed = password;
    if (!purpose) return;
    setError(null);
    startTransition(async () => {
      const result = await action(typed);
      setPassword("");
      if (!result.secret) {
        setError(result.error ?? "Couldn't show the token.");
        return;
      }
      setAsk(null);
      if (purpose === "show") {
        setSecret(result.secret);
        return;
      }
      try {
        await navigator.clipboard.writeText(result.secret);
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
          onClick={() => {
            setError(null);
            setAsk("copy");
          }}
          className="flex h-11 shrink-0 items-center justify-center px-2 text-[0.8125rem] font-semibold text-fg-secondary hover:text-fg disabled:opacity-60"
        >
          {copied ? "Copied" : "Copy"}
        </button>
      </div>
      {ask && (
        <form onSubmit={submit} className="flex flex-wrap items-center gap-2">
          <label htmlFor="reveal-password" className="text-sm font-semibold">
            Account password
          </label>
          <input
            id="reveal-password"
            type="password"
            autoComplete="current-password"
            required
            autoFocus
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            className="h-11 min-w-0 flex-1 rounded-control border border-line-strong bg-card px-3"
          />
          <button
            type="submit"
            disabled={pending || password === ""}
            className="h-11 rounded-control bg-accent px-4 text-sm font-bold text-on-accent disabled:opacity-60"
          >
            {ask === "copy" ? "Confirm and copy" : "Confirm and show"}
          </button>
          <button
            type="button"
            onClick={() => {
              setAsk(null);
              setPassword("");
              setError(null);
            }}
            className="h-11 px-3 text-sm font-semibold text-fg-secondary hover:text-fg"
          >
            Cancel
          </button>
        </form>
      )}
      {error && (
        <span role="alert" className="text-failed-fg">
          {error}
        </span>
      )}
    </>
  );
}
