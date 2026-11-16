/*
 * The website's Paddle settings (P20-83). No `server-only` here on purpose:
 * the proxy needs the environment to build the billing page's CSP, and a
 * `server-only` import can't be used from it. Nothing in this file is
 * secret: Paddle's client-side token is public by design (it can only open
 * checkouts), but it still comes from the environment, never from the
 * source. The server-side API key lives only in the backend.
 */

export type PaddleEnvironment = "sandbox" | "production";

export type PaddleConfig = {
  /** Paddle's client-side token (`test_…` for sandbox, `live_…` for production). */
  clientToken: string;
  environment: PaddleEnvironment;
};

/**
 * The Paddle settings, or null — web checkout is off unless a client token
 * is set and matches its environment (a `live_` token with `sandbox`, or the
 * reverse, is a misconfiguration and turns checkout off rather than sending
 * a customer to the wrong place). `PADDLE_ENV` defaults to sandbox.
 */
export function getPaddleConfig(
  env: Record<string, string | undefined> = process.env,
): PaddleConfig | null {
  const token = env.PADDLE_CLIENT_TOKEN?.trim();
  if (!token || !/^(test|live)_[A-Za-z0-9]{10,}$/.test(token)) return null;
  const environment: PaddleEnvironment = env.PADDLE_ENV === "production" ? "production" : "sandbox";
  const expected = environment === "production" ? "live_" : "test_";
  if (!token.startsWith(expected)) return null;
  return { clientToken: token, environment };
}

/** Paddle.js, from Paddle's own CDN. The only third-party script on the site. */
export const PADDLE_SCRIPT_URL = "https://cdn.paddle.com/paddle/v2/paddle.js";

/** The one page that loads Paddle.js, and so the one CSP exception. */
export const BILLING_PATH = "/account/billing";

export function isBillingPath(pathname: string): boolean {
  return pathname === BILLING_PATH || pathname === `${BILLING_PATH}/`;
}
