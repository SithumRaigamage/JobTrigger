/*
 * P20-75: the website's part of the analytics event catalogue
 * (docs/subscription/04-email-and-analytics.md §4.1). Names are shared with
 * the app and the backend. Only these can be sent.
 *
 * Data rule: tool, plan and limit names only — never an email, account id,
 * server URL, repository name or token.
 */
export const ANALYTICS_EVENTS = ["signup", "server_added", "limit_hit", "pricing_view"] as const;

export type AnalyticsEventName = (typeof ANALYTICS_EVENTS)[number];

type Primitive = string | number | boolean;

/**
 * Up to ten entries with identifier keys and short primitive values; the
 * rest is dropped. Same rules as the app's and the backend's.
 */
export function cleanAnalyticsData(
  data: Record<string, unknown> | undefined,
): Record<string, Primitive> | undefined {
  if (!data) return undefined;
  const out: Record<string, Primitive> = {};
  for (const [key, value] of Object.entries(data).slice(0, 10)) {
    if (!/^[a-zA-Z][a-zA-Z0-9_]{0,39}$/.test(key)) continue;
    if (typeof value === "number" || typeof value === "boolean") out[key] = value;
    else if (typeof value === "string" && value.length <= 64) out[key] = value;
  }
  return Object.keys(out).length > 0 ? out : undefined;
}
