/// Compact "how long ago" text for build timestamps, e.g. `2h ago`
/// (US-JX-05, US-JX-09). Pure, with [now] injectable for tests.
String relativeTime(DateTime then, {DateTime? now}) {
  final elapsed = (now ?? DateTime.now()).difference(then);
  if (elapsed.isNegative || elapsed.inSeconds < 60) return 'just now';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
  if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
  if (elapsed.inDays < 30) return '${elapsed.inDays}d ago';
  final months = elapsed.inDays ~/ 30;
  if (months < 12) return '${months}mo ago';
  return '${elapsed.inDays ~/ 365}y ago';
}

/// A Jenkins epoch-milliseconds timestamp as a [DateTime].
DateTime fromJenkinsTimestamp(num millis) =>
    DateTime.fromMillisecondsSinceEpoch(millis.toInt());

/// A build duration from Jenkins' milliseconds, e.g. `4m 12s` or `1h 3m`.
String formatBuildDuration(num millis) {
  final total = Duration(milliseconds: millis.toInt());
  if (total.inSeconds < 1) return '<1s';
  if (total.inMinutes < 1) return '${total.inSeconds}s';
  if (total.inHours < 1) {
    return '${total.inMinutes}m ${total.inSeconds.remainder(60)}s';
  }
  return '${total.inHours}h ${total.inMinutes.remainder(60)}m';
}
