import type { AppFailure } from "./app-failure";

/** An outcome that's either a value or an AppFailure — never a thrown error. */
export type Result<T> = { ok: true; value: T } | { ok: false; failure: AppFailure };

export const ok = <T>(value: T): Result<T> => ({ ok: true, value });

export const fail = <T = never>(failure: AppFailure): Result<T> => ({ ok: false, failure });
