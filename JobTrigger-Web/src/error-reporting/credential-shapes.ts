/*
 * The shapes of credential material (E3). Mirrors
 * JobTrigger-Backend/security/credentialShapes.js and the Dart copy in
 * JobTrigger-Frontend/lib/core/error_reporting/credential_shapes.dart; the
 * list is in docs/error-reporting.md. Keep the three in step.
 *
 * Plain functions only: this file is bundled for the browser, the server
 * and the proxy.
 */

/** A Jenkins token: 32 hex characters, or the modern `11`-prefixed form. */
export const TOKEN_SHAPE = /(?<![0-9a-f])((?:11)?[0-9a-f]{32})(?![0-9a-f])/g;
export const TOKEN_VALUE = /^(11)?[0-9a-f]{32}$/;

/** Keys whose value is a credential, after `normaliseKey`. */
export const CREDENTIAL_KEYS: ReadonlySet<string> = new Set([
  "password",
  "passwd",
  "pass",
  "token",
  "apitoken",
  "accesstoken",
  "authtoken",
  "bearertoken",
  "jenkinstoken",
  "personalaccesstoken",
  "pat",
  "secret",
  "paramtoken",
  "credential",
  "credentials",
  "auth",
  "authorization",
  "apikey",
  "apisecret",
  "privatekey",
]);

export const BASIC_HEADER = /Basic\s+([A-Za-z0-9+/]{12,}={0,2})/g;
export const BEARER_HEADER = /Bearer\s+([A-Za-z0-9._-]{16,})/g;
export const MONGODB_URI = /mongodb(?:\+srv)?:\/\/[^:@/\s'"`]+:([^@/\s'"`]+)@/g;
export const PLACEHOLDER_PASSWORD = /^(<[^<>]*>|\$\{[^{}]*\}|\*+)$/;

export function normaliseKey(key: string): string {
  return key.toLowerCase().replace(/[^a-z]/g, "");
}
