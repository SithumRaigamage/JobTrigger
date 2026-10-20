import '../../navigation/app_routes.dart';

/// The router location that opens a tapped notification's [payload]
/// (AUD-45): always the open-link screen, so the job is resolved against
/// the saved servers and a different server is switched to only after the
/// user confirms. Never pushed straight onto the active server's client.
///
/// [payload] is a `jobtrigger://app/open?url=…&server=…` link, or a bare
/// job URL from a notification posted before AUD-45.
String openLinkLocation(String payload) {
  final uri = Uri.tryParse(payload);
  final query = uri != null && uri.scheme == 'jobtrigger'
      ? {
          'url': uri.queryParameters['url'] ?? '',
          'server': ?uri.queryParameters['server'],
        }
      : {'url': payload};
  return Uri(path: AppRoutes.openLink, queryParameters: query).toString();
}
