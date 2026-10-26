"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import { failureMessage } from "@/domain/app-failure";
import type { Credential, Tool } from "@/domain/credentials";
import type { Result } from "@/domain/result";
import { authed } from "@/server/authed";
import {
  createGitHub,
  createJenkins,
  createSonarQube,
  deleteCredential,
  setDefaultCredential,
  updateGitHub,
  updateJenkins,
  updateSonarQube,
} from "@/server/credentials-api";
import { requireSession } from "@/server/guard";

import { parseServerForm, type FieldErrors } from "./server-input";

export type ActionState = { error?: string };

const tool = z.enum(["jenkins", "github", "sonarqube"]);
/** Mongo ObjectIds; nothing else is sent to the backend as a path segment. */
const credentialId = z.string().regex(/^[A-Za-z0-9]{1,64}$/);

const makeActiveForm = z.object({ tool, id: credentialId });

/** Makes a credential its tool's default (US-WEB-18). */
export async function makeActiveAction(
  _previous: ActionState,
  form: FormData,
): Promise<ActionState> {
  const session = await requireSession();
  const parsed = makeActiveForm.safeParse(Object.fromEntries(form));
  if (!parsed.success) return { error: "That server couldn't be found." };

  const result = await authed(session, (token) =>
    setDefaultCredential(token, parsed.data.tool, parsed.data.id),
  );
  if (!result.ok) return { error: failureMessage(result.failure) };
  revalidatePath("/servers");
  return {};
}

export type ServerFormState = {
  error?: string;
  fields?: FieldErrors;
};

const addForm = z.object({ tool });

/**
 * Adds a Jenkins server, GitHub account or SonarQube server (US-WEB-12,
 * 13, 14), then goes to "Now open the app" (US-WEB-17). The token travels
 * browser → this server → backend over HTTPS and is never logged or sent
 * back in the form state.
 */
export async function addServerAction(
  _previous: ServerFormState,
  form: FormData,
): Promise<ServerFormState> {
  const session = await requireSession();
  const picked = addForm.safeParse({ tool: form.get("tool") });
  if (!picked.success) return { error: "Choose a tool first." };

  const parsed = parseServerForm(picked.data.tool, form);
  if (!parsed.ok) return { fields: parsed.fields };

  const result = await authed(session, async (token): Promise<Result<Credential>> => {
    switch (parsed.tool) {
      case "jenkins":
        return createJenkins(token, parsed.input);
      case "github":
        return createGitHub(token, parsed.input);
      case "sonarqube":
        return createSonarQube(token, parsed.input);
    }
  });
  if (!result.ok) return { error: failureMessage(result.failure) };

  revalidatePath("/servers");
  redirect(`/servers/saved?tool=${parsed.tool}&id=${encodeURIComponent(result.value.id)}`);
}

/**
 * Saves changes to a server (US-WEB-15). A blank secret is left out of the
 * PUT, so the backend keeps the saved one — this server never reads it.
 * A credential whose secret the backend can't decrypt (AUD-63) needs a new
 * one, so a blank secret is refused then.
 */
export async function updateServerAction(
  target: { tool: Tool; id: string; needsReentry: boolean },
  _previous: ServerFormState,
  form: FormData,
): Promise<ServerFormState> {
  const session = await requireSession();
  const checked = makeActiveForm.safeParse(target);
  if (!checked.success) return { error: "That server couldn't be found." };

  const parsed = parseServerForm(checked.data.tool, form, !target.needsReentry);
  if (!parsed.ok) return { fields: parsed.fields };

  const { id } = checked.data;
  const result = await authed(session, async (token): Promise<Result<Credential>> => {
    switch (parsed.tool) {
      case "jenkins":
        return updateJenkins(token, id, parsed.input);
      case "github":
        return updateGitHub(token, id, parsed.input);
      case "sonarqube":
        return updateSonarQube(token, id, parsed.input);
    }
  });
  if (!result.ok) return { error: failureMessage(result.failure) };

  revalidatePath("/servers");
  redirect("/servers");
}

/** Deletes a server after the confirmation dialog (US-WEB-15). */
export async function deleteServerAction(
  target: { tool: Tool; id: string },
  _previous: ActionState,
): Promise<ActionState> {
  const session = await requireSession();
  const checked = makeActiveForm.safeParse(target);
  if (!checked.success) return { error: "That server couldn't be found." };

  const result = await authed(session, (token) =>
    deleteCredential(token, checked.data.tool, checked.data.id),
  );
  if (!result.ok) return { error: failureMessage(result.failure) };

  revalidatePath("/servers");
  redirect("/servers");
}
