"use client";

import { useActionState } from "react";

import type { Tool } from "@/domain/credentials";

import { makeActiveAction, type ActionState } from "./actions";

const initial: ActionState = {};

/** "Make active" for a non-default row (design 10; US-WEB-18). */
export function MakeActiveButton({ tool, id, name }: { tool: Tool; id: string; name: string }) {
  const [state, formAction, pending] = useActionState(makeActiveAction, initial);

  return (
    <form action={formAction} className="flex flex-col items-start gap-1">
      <input type="hidden" name="tool" value={tool} />
      <input type="hidden" name="id" value={id} />
      <button
        type="submit"
        disabled={pending}
        className="h-9 rounded-[10px] border border-line-strong bg-card px-3 text-[0.8125rem] font-semibold text-fg hover:bg-raised disabled:opacity-70"
      >
        {pending ? "Switching…" : "Make active"}
        <span className="sr-only">{` ${name}`}</span>
      </button>
      {state.error && (
        <span role="alert" className="text-xs font-semibold text-failed-fg">
          {state.error}
        </span>
      )}
    </form>
  );
}
