import type { Tool } from "@/domain/credentials";

/** "How do I get this?" per tool (design 11; US-WEB-16), as approved. */
export const toolHelp: Record<Tool, { title: string; steps: string[]; tip: string }> = {
  jenkins: {
    title: "Getting a Jenkins API token",
    steps: [
      "Open Jenkins and sign in.",
      "Click your name (top right), then Security.",
      "Under API Token, click Add new token and name it “JobTrigger”.",
      "Click Generate and copy it. Jenkins shows it only once.",
    ],
    tip: "Use an API token, not your password — it works with single sign-on and you can revoke it on its own.",
  },
  github: {
    title: "Getting a GitHub token",
    steps: [
      "Settings → Developer settings → Personal access tokens → Fine-grained tokens.",
      "Generate new token; pick only the repositories you need.",
      "Repository permissions: Actions “Read and write”, Metadata “Read-only”.",
      "Set an expiry date, generate, and copy it.",
    ],
    tip: "A fine-grained token limited to a few repositories is safer than a classic one.",
  },
  sonarqube: {
    title: "Getting a SonarQube token",
    steps: [
      "Sign in to SonarQube.",
      "Open My Account → Security.",
      "Name it “JobTrigger” and choose User token.",
      "Click Generate and copy it.",
    ],
    tip: "Set an expiry date so an old token stops working on its own.",
  },
};

/** The tool-picker tiles' second line (design 11). */
export const toolNeeds: Record<Tool, string> = {
  jenkins: "URL · user · API token",
  github: "Personal access token",
  sonarqube: "URL · user token",
};
