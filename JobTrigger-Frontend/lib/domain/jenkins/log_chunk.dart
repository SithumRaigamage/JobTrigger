/// One incremental read of a build's console log via Jenkins' Progressive
/// Text API — see `docs/api-reference.md`.
class LogChunk {
  const LogChunk({
    required this.text,
    required this.nextOffset,
    required this.hasMoreData,
  });

  final String text;
  final int nextOffset;
  final bool hasMoreData;
}
