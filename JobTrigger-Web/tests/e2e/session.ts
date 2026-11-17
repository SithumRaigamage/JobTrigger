import { sealData } from "iron-session";

import { E2E_SESSION_SECRET } from "../../playwright.config";

const b64 = (value: unknown) => Buffer.from(JSON.stringify(value)).toString("base64url");

/** A session cookie value as the site would set it, for edge cases. */
export async function sealedSession(data: {
  accessToken?: string;
  refreshToken?: string;
  email?: string;
  lastActivity?: number;
}) {
  return sealData(data, { password: E2E_SESSION_SECRET });
}

/** A JWT-shaped token the fake backend would reject (unknown user). */
export const fakeToken = (typ: "access" | "refresh", expInSeconds: number) =>
  `fake.${b64({ id: "nobody", typ, tv: 0, exp: Math.floor(Date.now() / 1000) + expInSeconds })}.sig`;

let counter = 0;
/** An email no other test uses, so parallel tests don't share state. */
export const uniqueEmail = (prefix = "user") =>
  `${prefix}-${Date.now()}-${process.pid}-${counter++}@acme.dev`;
