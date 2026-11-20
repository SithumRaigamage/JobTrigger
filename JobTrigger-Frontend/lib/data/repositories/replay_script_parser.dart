import '../../domain/jenkins/replay_script.dart';

/// US-JX-16: reads the pipeline definition out of a job's `config.xml`.
///
/// A regex over the one element is enough (and adds no XML package): Jenkins
/// writes `<definition class="…CpsFlowDefinition" plugin="…">` with a
/// `<script>` and a `<sandbox>` child, and escapes the script's text.
ReplayScript parseReplayScript(String configXml) {
  final definition = RegExp(
    r'<definition\s+class="([^"]+)"[^>]*>(.*?)</definition>',
    dotAll: true,
  ).firstMatch(configXml);
  if (definition == null) return const NoReplayScript();
  final kind = definition.group(1)!;
  final body = definition.group(2)!;
  if (kind.endsWith('CpsScmFlowDefinition')) return const ScmReplayScript();
  if (!kind.endsWith('CpsFlowDefinition')) return const NoReplayScript();
  final script = RegExp(
    r'<script>(.*?)</script>',
    dotAll: true,
  ).firstMatch(body)?.group(1);
  final sandbox = RegExp(
    r'<sandbox>\s*(true|false)\s*</sandbox>',
  ).firstMatch(body)?.group(1);
  return InlineReplayScript(
    script: decodeXmlText(script ?? ''),
    sandbox: sandbox == 'true',
  );
}

/// Decodes the five XML entities and numeric character references.
String decodeXmlText(String text) => text.replaceAllMapped(
  RegExp(r'&(#x[0-9a-fA-F]+|#[0-9]+|lt|gt|amp|quot|apos);'),
  (match) {
    final entity = match.group(1)!;
    if (entity.startsWith('#x')) {
      return String.fromCharCode(int.parse(entity.substring(2), radix: 16));
    }
    if (entity.startsWith('#')) {
      return String.fromCharCode(int.parse(entity.substring(1)));
    }
    return const {
      'lt': '<',
      'gt': '>',
      'amp': '&',
      'quot': '"',
      'apos': "'",
    }[entity]!;
  },
);
