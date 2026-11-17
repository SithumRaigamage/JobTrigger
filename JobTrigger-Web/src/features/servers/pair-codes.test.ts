import { describe, expect, it } from "vitest";

import type { Credential } from "@/domain/credentials";

import { buildPairCodes, pairQrSvg } from "./pair-codes";

const jenkins: Credential = {
  tool: "jenkins",
  id: "j1",
  name: "Acme production",
  url: "https://ci.acme.dev",
  username: "sam",
  isDefault: true,
  needsReentry: false,
  secretMask: "••••a91f",
  hasParamToken: false,
};

const github: Credential = {
  tool: "github",
  id: "g1",
  label: "Acme",
  defaultOwner: "acme",
  isDefault: false,
  needsReentry: false,
  secretMask: "••••be21",
};

describe("pairing codes", () => {
  it("draws an SVG QR", async () => {
    const svg = await pairQrSvg("jobtrigger://app/pair?url=x&name=y");

    expect(svg.trimStart().startsWith("<svg")).toBe(true);
  });

  it("makes one code per Jenkins server and skips other tools", async () => {
    const codes = await buildPairCodes([jenkins, github]);

    expect(codes).toHaveLength(1);
    expect(codes[0].id).toBe("j1");
    expect(codes[0].name).toBe("Acme production");
    expect(codes[0].svg).toContain("<svg");
  });

  it("skips a server with no name or address", async () => {
    const codes = await buildPairCodes([{ ...jenkins, name: " " }]);

    expect(codes).toEqual([]);
  });

  it("never encodes a secret", async () => {
    const codes = await buildPairCodes([{ ...jenkins, secretMask: "••••zzzz" }]);

    expect(codes[0].svg).not.toContain("zzzz");
  });
});
