import type { Credential } from "@/domain/credentials";
import { maskSecret } from "@/domain/mask";

/**
 * The sample servers of the public /demo page (E2, PE-16). Fixed data: the
 * page makes no request, so nothing here is, or looks like, a real server.
 * The `.invalid` domain is reserved (RFC 2606) and never resolves, and the
 * secrets are placeholders shown only as masks, as in the real portal.
 */
export const demoServers: Credential[] = [
  {
    tool: "jenkins",
    id: "demo-jenkins",
    name: "Demo Jenkins",
    url: "https://jenkins.demo.invalid",
    username: "demo",
    isDefault: true,
    needsReentry: false,
    secretMask: maskSecret("demo-token-0001"),
    hasParamToken: false,
  },
  {
    tool: "jenkins",
    id: "demo-jenkins-staging",
    name: "Demo staging Jenkins",
    url: "https://staging.jenkins.demo.invalid",
    username: "demo",
    isDefault: false,
    needsReentry: false,
    secretMask: maskSecret("demo-token-0002"),
    hasParamToken: false,
  },
  {
    tool: "github",
    id: "demo-github",
    label: "Demo GitHub",
    defaultOwner: "demo-org",
    isDefault: true,
    needsReentry: false,
    secretMask: maskSecret("demo-token-0003"),
  },
  {
    tool: "sonarqube",
    id: "demo-sonarqube",
    label: "Demo SonarQube",
    baseUrl: "https://sonarqube.demo.invalid",
    defaultOrganization: "",
    isDefault: true,
    needsReentry: false,
    secretMask: maskSecret("demo-token-0004"),
  },
];
