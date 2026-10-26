import { describe, expect, it } from "vitest";

import { parseServerForm } from "./server-input";

const form = (values: Record<string, string>) => {
  const data = new FormData();
  for (const [key, value] of Object.entries(values)) data.set(key, value);
  return data;
};

describe("parseServerForm", () => {
  it("trims a Jenkins server into the backend's input", () => {
    expect(
      parseServerForm(
        "jenkins",
        form({
          name: " Acme ",
          url: " https://ci.acme.dev/ ",
          username: " sam ",
          secret: " tok ",
          paramToken: "",
        }),
      ),
    ).toEqual({
      ok: true,
      tool: "jenkins",
      input: {
        name: "Acme",
        url: "https://ci.acme.dev",
        username: "sam",
        password: "tok",
        paramToken: "",
      },
    });
  });

  it("reports every missing Jenkins field with the app's URL rule", () => {
    expect(parseServerForm("jenkins", form({ url: "ci.acme.dev" }))).toEqual({
      ok: false,
      fields: {
        name: "Enter a name for this server.",
        secret: "Paste the API token.",
        url: "The URL must start with https:// (or http://).",
        username: "Enter your Jenkins username.",
      },
    });
  });

  it("maps a GitHub account and SonarQube server to their field names", () => {
    expect(
      parseServerForm("github", form({ name: "Work", secret: "ghp_x", owner: "acme" })),
    ).toMatchObject({
      input: { label: "Work", token: "ghp_x", defaultOwner: "acme" },
    });
    expect(
      parseServerForm(
        "sonarqube",
        form({
          name: "Cloud",
          url: "https://sonarcloud.io",
          secret: "squ_x",
          organization: "acme",
        }),
      ),
    ).toMatchObject({
      input: {
        label: "Cloud",
        baseUrl: "https://sonarcloud.io",
        token: "squ_x",
        defaultOrganization: "acme",
      },
    });
  });

  it("allows a blank secret when editing (keep the saved one)", () => {
    expect(parseServerForm("github", form({ name: "Work", secret: "" }), true)).toMatchObject({
      ok: true,
    });
    expect(parseServerForm("github", form({ name: "Work", secret: "" }))).toMatchObject({
      ok: false,
    });
  });
});
