/*
 * What counts as a usable server URL, the app's rules exactly
 * (JobTrigger-Frontend/lib/domain/credential/server_url.dart, AUD-14 /
 * AUD-52). Plain http:// is allowed (LAN servers are common) but always
 * flagged, because the secret then travels unencrypted.
 */

/** Trimmed, without trailing slashes. */
export function normalizeServerUrl(raw: string): string {
  return raw.trim().replace(/\/+$/, "");
}

/** Why [raw] can't be the address of a [product] server, or null. */
export function serverUrlProblem(raw: string, product: string): string | null {
  const value = normalizeServerUrl(raw);
  if (!value) return `Enter the ${product} URL.`;
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    return "The URL must start with https:// (or http://).";
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") {
    return "The URL must start with https:// (or http://).";
  }
  if (!url.hostname) return "The URL needs a host name, e.g. ci.example.com.";
  if (url.search || url.hash || value.includes("?") || value.includes("#")) {
    return `Use the ${product} address only, without ? or # parts.`;
  }
  return null;
}

/** True for http://, where credentials travel unencrypted. */
export function isCleartextUrl(raw: string): boolean {
  return /^http:\/\//i.test(normalizeServerUrl(raw));
}
