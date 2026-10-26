// @vitest-environment node
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import {
  createJenkins,
  listGitHub,
  listJenkins,
  listSonarQube,
  setDefaultCredential,
  updateJenkins,
} from "./credentials-api";

vi.mock("./config", () => ({
  getConfig: () => ({ backendUrl: "http://backend.test", sessionSecret: "x", siteUrl: "" }),
}));

const fetchMock = vi.fn<typeof fetch>();
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

beforeEach(() => vi.stubGlobal("fetch", fetchMock));
afterEach(() => {
  fetchMock.mockReset();
  vi.unstubAllGlobals();
});

const JENKINS_TOKEN = "fake-jenkins-token-a91f";
const PARAM_TOKEN = "trigger-token-secret-value";
const GITHUB_TOKEN = "github_pat_11ABCDEFG0123456789_secretpart";
const SONAR_TOKEN = "squ_0123456789abcdef0123456789abcdef02cd";

const jenkinsRow = {
  _id: "j1",
  userId: "u1",
  serverName: "Acme production",
  jenkinsURL: "https://ci.acme.dev",
  username: "sam",
  password: JENKINS_TOKEN,
  paramToken: PARAM_TOKEN,
  isDefault: true,
  needsReentry: false,
  __v: 0,
};

describe("credential reads", () => {
  it("mask every secret and never return one in full", async () => {
    fetchMock.mockImplementation(async (url) => {
      const path = new URL(String(url)).pathname;
      if (path === "/api/credentials") return json([jenkinsRow]);
      if (path === "/api/github-credentials")
        return json([{ _id: "g1", label: "Work", token: GITHUB_TOKEN, isDefault: false }]);
      return json([
        {
          _id: "s1",
          label: "Cloud",
          baseUrl: "https://sonarcloud.io",
          token: SONAR_TOKEN,
          isDefault: true,
        },
      ]);
    });

    const results = [await listJenkins("t"), await listGitHub("t"), await listSonarQube("t")];
    const everything = JSON.stringify(results);

    for (const secret of [JENKINS_TOKEN, PARAM_TOKEN, GITHUB_TOKEN, SONAR_TOKEN]) {
      expect(everything).not.toContain(secret);
    }
    expect(results[0]).toEqual({
      ok: true,
      value: [
        {
          tool: "jenkins",
          id: "j1",
          name: "Acme production",
          url: "https://ci.acme.dev",
          username: "sam",
          isDefault: true,
          needsReentry: false,
          secretMask: "••••a91f",
          hasParamToken: true,
        },
      ],
    });
  });

  it("reports an unreadable secret (AUD-63) with no mask", async () => {
    fetchMock.mockResolvedValue(json([{ ...jenkinsRow, password: null, needsReentry: true }]));

    const result = await listJenkins("t");

    expect(result.ok && result.value[0]).toMatchObject({ needsReentry: true, secretMask: null });
  });
});

describe("credential writes", () => {
  it("send the backend's field names when adding a Jenkins server", async () => {
    fetchMock.mockResolvedValue(json(jenkinsRow, 201));

    await createJenkins("t", {
      name: "Acme production",
      url: "https://ci.acme.dev",
      username: "sam",
      password: JENKINS_TOKEN,
      paramToken: "",
    });

    expect(JSON.parse(String(fetchMock.mock.calls[0][1]!.body))).toEqual({
      serverName: "Acme production",
      jenkinsURL: "https://ci.acme.dev",
      username: "sam",
      password: JENKINS_TOKEN,
      paramToken: "",
    });
  });

  it("leave a blank secret out of an update, so the saved one is kept (US-WEB-15)", async () => {
    fetchMock.mockResolvedValue(json(jenkinsRow));

    await updateJenkins("t", "j1", {
      name: "Renamed",
      url: "https://ci.acme.dev",
      username: "sam",
      password: "",
      paramToken: "",
    });

    const [url, init] = fetchMock.mock.calls[0];
    expect(String(url)).toBe("http://backend.test/api/credentials/j1");
    expect(init!.method).toBe("PUT");
    const body = JSON.parse(String(init!.body));
    expect(body).not.toHaveProperty("password");
    expect(body).not.toHaveProperty("paramToken");
    expect(body.serverName).toBe("Renamed");
  });

  it("switch the default with the tool's switch endpoint", async () => {
    fetchMock.mockResolvedValue(json({ _id: "g1" }));

    expect(await setDefaultCredential("t", "github", "g1")).toEqual({ ok: true, value: null });
    expect(String(fetchMock.mock.calls[0][0])).toBe(
      "http://backend.test/api/github-credentials/switch/g1",
    );
  });
});
