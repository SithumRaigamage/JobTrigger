import "server-only";

import { cleanAnalyticsData, type AnalyticsEventName } from "@/domain/analytics-events";

import { getAnalyticsConfig } from "./config";

/*
 * P20-77: anonymous product events, sent from this server to the
 * self-hosted Umami. No tracker script runs in the browser, so the CSP
 * (docs/web-architecture.md "Security headers") is unchanged.
 *
 * Fire-and-forget: never throws, never delays a response by more than the
 * 2-second timeout, and a no-op when Umami isn't configured.
 */

// Umami drops requests without a browser-like User-Agent (bot filter).
const USER_AGENT = "Mozilla/5.0 (compatible; JobTrigger-Web)";

type Sender = (url: string, body: unknown) => Promise<void>;

async function defaultSender(url: string, body: unknown): Promise<void> {
  const response = await fetch(url, {
    method: "POST",
    headers: { "content-type": "application/json", "user-agent": USER_AGENT },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(2000),
    cache: "no-store",
  });
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
}

let sender: Sender = defaultSender;

/** Tests only: replace the network call. */
export function setAnalyticsSenderForTests(fake: Sender | null): void {
  sender = fake ?? defaultSender;
}

/** Records [name]; resolves to whether it was sent. Never rejects. */
export async function track(
  name: AnalyticsEventName,
  data?: Record<string, unknown>,
): Promise<boolean> {
  const config = getAnalyticsConfig();
  if (!config) return false;
  const cleaned = cleanAnalyticsData(data);
  try {
    await sender(`${config.url}/api/send`, {
      type: "event",
      payload: {
        website: config.websiteId,
        hostname: "web.jobtrigger.local",
        url: "/",
        name,
        ...(cleaned ? { data: cleaned } : {}),
      },
    });
    return true;
  } catch (error) {
    console.warn(
      `analytics: ${name} not sent (${error instanceof Error ? error.message : "error"})`,
    );
    return false;
  }
}
