/// A Riverpod `retry` that never retries (P19-03): `@Riverpod(retry: noRetry)`.
///
/// Riverpod's default retries a failed provider up to 10 times, and while it
/// does the value reads as loading, so a screen keeps its spinner instead of
/// showing the error and its Retry button. Providers whose failure the user
/// can act on (an unreachable Jenkins) opt out.
Duration? noRetry(int retryCount, Object error) => null;
