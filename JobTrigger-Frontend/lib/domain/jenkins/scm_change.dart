/// One SCM commit included in a build (US-PIPE-03) — Jenkins' `changeSet`.
class ScmChange {
  const ScmChange({required this.author, required this.message});

  final String author;
  final String message;
}
