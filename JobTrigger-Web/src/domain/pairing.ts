/*
 * NR-03: the link a pairing QR carries (docs/implemented/improvement-plan.md).
 *
 * The app parses exactly this shape — `jobtrigger://app/pair?url=…&name=…`
 * (`JobTrigger-Frontend/lib/domain/credential/pair_link.dart`), so the two
 * must stay in step. Only the server's name, address and username go in:
 * never the token, so a QR shown on a screen (or photographed) leaks nothing
 * that the user's own Jenkins login page wouldn't.
 */

export const PAIR_LINK_PREFIX = "jobtrigger://app/pair";

export type PairTarget = {
  /** The Jenkins address, as saved (https:// or a LAN http://). */
  url: string;
  /** The server's name in JobTrigger, shown on the phone. */
  name: string;
  /** Optional: prefilled on the phone, still editable there. */
  username?: string;
};

/** `jobtrigger://app/pair?url=…&name=…&username=…`. */
export function buildPairLink({ url, name, username }: PairTarget): string {
  const params = new URLSearchParams({ url, name });
  if (username) params.set("username", username);
  return `${PAIR_LINK_PREFIX}?${params.toString()}`;
}

/**
 * The pairing link for a saved Jenkins server, or null when it has no name or
 * address to put in one (a half-saved credential the QR can't help with).
 */
export function pairLinkFor(server: {
  url: string;
  name: string;
  username?: string;
}): string | null {
  const url = server.url.trim();
  const name = server.name.trim();
  if (!url || !name) return null;
  return buildPairLink({ url, name, username: server.username?.trim() });
}
