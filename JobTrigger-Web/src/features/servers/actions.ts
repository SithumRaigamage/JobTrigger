"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";

import { failureMessage } from "@/domain/app-failure";
import { authed } from "@/server/authed";
import { setDefaultCredential } from "@/server/credentials-api";
import { requireSession } from "@/server/guard";

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
