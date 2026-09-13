/// A minimal Ok/Err result type, chosen over `fpdart`'s `Either` in Phase 0
/// to avoid a new dependency for a shape this small — see
/// `docs/architecture.md#6-error-handling`. Used everywhere a repository
/// method can fail: `Future<Result<T, AppFailure>>`.
sealed class Result<T, E> {
  const Result();
}

final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);

  final T value;
}

final class Err<T, E> extends Result<T, E> {
  const Err(this.error);

  final E error;
}

extension ResultX<T, E> on Result<T, E> {
  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  /// Collapses both branches into a single value, mirroring `Either.fold`.
  R fold<R>(R Function(T value) onOk, R Function(E error) onErr) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final error) => onErr(error),
      };

  /// Transforms the success value, leaving an error branch untouched.
  Result<R, E> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final error) => Err(error),
  };
}
