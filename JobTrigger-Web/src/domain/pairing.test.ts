import { describe, expect, it } from "vitest";

import { buildPairLink, pairLinkFor, PAIR_LINK_PREFIX } from "./pairing";

describe("pairing link", () => {
  it("builds the shape the app parses", () => {
    const link = buildPairLink({
      url: "https://ci.example.com",
      name: "Acme production",
      username: "deploy",
    });

    expect(link.startsWith(`${PAIR_LINK_PREFIX}?`)).toBe(true);
    const query = new URLSearchParams(link.split("?")[1]);
    expect(query.get("url")).toBe("https://ci.example.com");
    expect(query.get("name")).toBe("Acme production");
    expect(query.get("username")).toBe("deploy");
  });

  it("escapes an address that carries its own query string", () => {
    const link = buildPairLink({
      url: "https://ci.example.com/?folder=release",
      name: "Release",
    });

    expect(new URLSearchParams(link.split("?")[1]).get("url")).toBe(
      "https://ci.example.com/?folder=release",
    );
  });

  it("never puts a secret in the link", () => {
    const link = buildPairLink({ url: "https://ci.example.com", name: "Acme" });

    expect(link).not.toMatch(/token|password|secret/i);
    expect(new URLSearchParams(link.split("?")[1]).has("username")).toBe(false);
  });

  it("skips a server that has no name or address", () => {
    expect(pairLinkFor({ url: " ", name: "Acme" })).toBeNull();
    expect(pairLinkFor({ url: "https://ci.example.com", name: "" })).toBeNull();
  });

  it("pairs a saved server, trimming what it carries", () => {
    const link = pairLinkFor({
      url: " https://ci.example.com ",
      name: " Acme ",
      username: " deploy ",
    });

    expect(link).not.toBeNull();
    const query = new URLSearchParams(link!.split("?")[1]);
    expect(query.get("url")).toBe("https://ci.example.com");
    expect(query.get("name")).toBe("Acme");
    expect(query.get("username")).toBe("deploy");
  });
});
