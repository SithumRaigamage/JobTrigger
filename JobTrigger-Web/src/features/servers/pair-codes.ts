import "server-only";

import QRCode from "qrcode";

import type { Credential } from "@/domain/credentials";
import { pairLinkFor } from "@/domain/pairing";

/*
 * NR-03: the pairing codes for a user's saved Jenkins servers.
 *
 * Built here, on the server, so the view stays a plain component that renders
 * data (and its tests don't have to render an async component). Only the
 * server's name, address and username are encoded — never the token, so a QR
 * on a screen or in a photo leaks nothing.
 */
export type PairCode = { id: string; name: string; svg: string };

/** One SVG per saved Jenkins server; a server that can't be drawn is skipped. */
export async function buildPairCodes(servers: Credential[]): Promise<PairCode[]> {
  const codes: PairCode[] = [];
  for (const server of servers) {
    if (server.tool !== "jenkins") continue;
    const link = pairLinkFor(server);
    if (!link) continue;
    try {
      codes.push({ id: server.id, name: server.name, svg: await pairQrSvg(link) });
    } catch {
      // A code that can't be generated must not take the page down.
      continue;
    }
  }
  return codes;
}

/** The SVG for one pairing link. Its own export so a test can check it. */
export function pairQrSvg(link: string): Promise<string> {
  return QRCode.toString(link, {
    type: "svg",
    margin: 1,
    width: 168,
    errorCorrectionLevel: "M",
  });
}
