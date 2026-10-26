import { describe, expect, it } from "vitest";

import { isCleartextUrl, normalizeServerUrl, serverUrlProblem } from "./server-url";

describe("server URL rules (the app's server_url.dart)", () => {
  it("trims and drops trailing slashes", () => {
    expect(normalizeServerUrl("  https://ci.acme.dev//  ")).toBe("https://ci.acme.dev");
  });

  it.each([
    ["", "Enter the Jenkins URL."],
    ["ci.acme.dev", "The URL must start with https:// (or http://)."],
    ["ftp://ci.acme.dev", "The URL must start with https:// (or http://)."],
    ["https://ci.acme.dev/?x=1", "Use the Jenkins address only, without ? or # parts."],
    ["https://ci.acme.dev/#top", "Use the Jenkins address only, without ? or # parts."],
  ])("%j → %s", (raw, problem) => {
    expect(serverUrlProblem(raw, "Jenkins")).toBe(problem);
  });

  it("accepts https and LAN http, flagging http as cleartext", () => {
    expect(serverUrlProblem("https://ci.acme.dev/jenkins", "Jenkins")).toBeNull();
    expect(serverUrlProblem("http://jenkins.lan:8080", "Jenkins")).toBeNull();
    expect(isCleartextUrl("http://jenkins.lan:8080")).toBe(true);
    expect(isCleartextUrl("https://ci.acme.dev")).toBe(false);
  });
});
