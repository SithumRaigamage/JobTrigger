import type { Credential, Tool } from "./credentials";

/** Display names, singular and plural, as the app and designs use them. */
export const toolNames: Record<Tool, { name: string; one: string; many: string }> = {
  jenkins: { name: "Jenkins", one: "Jenkins server", many: "Jenkins servers" },
  github: { name: "GitHub", one: "GitHub account", many: "GitHub accounts" },
  sonarqube: { name: "SonarQube", one: "SonarQube server", many: "SonarQube servers" },
};

export const tools: Tool[] = ["jenkins", "github", "sonarqube"];

/** The row title: a server's name or an account's label. */
export function credentialName(credential: Credential): string {
  return credential.tool === "jenkins" ? credential.name : credential.label;
}

/** The "Address" column: where it points and as whom. */
export function credentialAddress(credential: Credential): string {
  switch (credential.tool) {
    case "jenkins":
      return `${credential.url} · ${credential.username}`;
    case "github":
      return credential.defaultOwner ? `@${credential.defaultOwner}` : "All repositories";
    case "sonarqube":
      return credential.defaultOrganization
        ? `${credential.baseUrl} · ${credential.defaultOrganization}`
        : credential.baseUrl;
  }
}
