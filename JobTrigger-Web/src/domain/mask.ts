/**
 * How a saved secret is shown on the web (US-WEB-11): "••••" plus its last
 * four characters, so a user can tell two tokens apart without the browser
 * ever holding one (docs/web-architecture.md §2). Secrets shorter than
 * eight characters show no characters at all: four of six would be most of
 * the secret.
 */
export function maskSecret(secret: string): string {
  return secret.length >= 8 ? `••••${secret.slice(-4)}` : "••••";
}
