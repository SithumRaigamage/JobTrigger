/*
 * Sign-up and sign-in rules, kept in step with the app's AuthValidation
 * (JobTrigger-Frontend/lib/domain/auth/auth_validation.dart) and the
 * backend's authController (US-WEB-10: "the same validation rules as the
 * app"). The backend is the authority; these give quick feedback.
 */

/** Something, `@`, something, `.`, something, with no spaces. */
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const MIN_PASSWORD_LENGTH = 8;

/** bcrypt ignores everything past 72 bytes; the backend refuses longer. */
export const MAX_PASSWORD_BYTES = 72;

export function isValidEmail(email: string): boolean {
  return EMAIL.test(email.trim());
}

/** Why [password] can't be a new password, or null. Same copy as the backend. */
export function newPasswordProblem(password: string): string | null {
  if (password.length < MIN_PASSWORD_LENGTH) {
    return `Password must be at least ${MIN_PASSWORD_LENGTH} characters long`;
  }
  if (new TextEncoder().encode(password).length > MAX_PASSWORD_BYTES) {
    return "Password is too long";
  }
  return null;
}
