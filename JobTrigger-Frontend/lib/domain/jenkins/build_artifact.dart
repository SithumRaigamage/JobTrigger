/// A file produced by a build (US-PIPE-07) — Jenkins' `artifacts[]`.
class BuildArtifact {
  const BuildArtifact({required this.fileName, required this.relativePath});

  final String fileName;

  /// Path relative to the build, used to fetch it: `{buildUrl}artifact/
  /// {relativePath}`. May contain `/` for artifacts in a subdirectory.
  final String relativePath;
}
