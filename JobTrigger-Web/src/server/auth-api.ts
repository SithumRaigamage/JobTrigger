import "server-only";

import { z } from "zod";

import type { Result } from "@/domain/result";

import { callBackend } from "./backend-client";

/*
 * JobTrigger-Backend /api/auth (docs/api-reference.md §1). Signup, login,
 * refresh and password change all answer with a fresh token pair: a
 * 15-minute access token and a 30-day refresh token (AUD-26).
 */

const tokenPair = z.object({
  token: z.string().min(1),
  refreshToken: z.string().min(1),
  user: z.object({ email: z.string() }),
});

export type TokenPair = { token: string; refreshToken: string; email: string };

const toPair = (result: Result<z.infer<typeof tokenPair>>): Result<TokenPair> =>
  result.ok
    ? {
        ok: true,
        value: {
          token: result.value.token,
          refreshToken: result.value.refreshToken,
          email: result.value.user.email,
        },
      }
    : result;

const message = z.object({ message: z.string() });

export async function login(email: string, password: string): Promise<Result<TokenPair>> {
  return toPair(
    await callBackend(
      { method: "POST", path: "/api/auth/login", body: { email, password } },
      tokenPair,
    ),
  );
}

export async function signup(email: string, password: string): Promise<Result<TokenPair>> {
  return toPair(
    await callBackend(
      { method: "POST", path: "/api/auth/signup", body: { email, password } },
      tokenPair,
    ),
  );
}

export async function refresh(refreshToken: string): Promise<Result<TokenPair>> {
  return toPair(
    await callBackend(
      { method: "POST", path: "/api/auth/refresh", body: { refreshToken } },
      tokenPair,
    ),
  );
}

/** Revokes every token on every device, this one included (US-WEB-20). */
export async function logoutAll(accessToken: string): Promise<Result<unknown>> {
  return callBackend({ method: "POST", path: "/api/auth/logout-all", accessToken }, message);
}

/** Revokes every other session and returns a fresh pair for this one (AUD-48). */
export async function changePassword(
  accessToken: string,
  currentPassword: string,
  newPassword: string,
): Promise<Result<TokenPair>> {
  return toPair(
    await callBackend(
      {
        method: "POST",
        path: "/api/auth/password",
        body: { currentPassword, newPassword },
        accessToken,
      },
      tokenPair,
    ),
  );
}

/** Deletes the account and every saved credential (AUD-48). */
export async function deleteAccount(
  accessToken: string,
  password: string,
): Promise<Result<unknown>> {
  return callBackend(
    { method: "DELETE", path: "/api/auth/account", body: { password }, accessToken },
    message,
  );
}
