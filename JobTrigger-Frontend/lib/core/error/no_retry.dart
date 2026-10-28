/// Riverpod's default is to retry a failed provider up to ten times with
/// growing delays, and the provider reads as *loading* throughout, so a
/// stopped Jenkins looks like an endless spinner. Jenkins data providers opt
/// out with `@Riverpod(retry: noRetry)`: the failure shows straight away,
/// with the error view's retry button and pull-to-refresh to try again.
Duration? noRetry(int retryCount, Object error) => null;
