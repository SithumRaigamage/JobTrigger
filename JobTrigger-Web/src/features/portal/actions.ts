"use server";

import { redirect } from "next/navigation";

import { getSession } from "@/server/session";

/**
 * Signs out of the website (US-WEB-20): clears the session cookie and goes
 * home. The backend's refresh token isn't revoked by this alone — "Sign
 * out of all devices" on Account does that (logout-all).
 */
export async function signOutAction() {
  const session = await getSession();
  session.destroy();
  redirect("/");
}
