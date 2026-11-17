/// NR-03: the link a pairing QR carries (`docs/implemented/improvement-plan.md`).
///
/// The website shows a QR for a saved Jenkins server; the phone's own Camera
/// app opens it, and the app lands on the add-server form with the name, URL
/// and username already filled. The token is never in the code — the user
/// types it, so a screenshot of the QR (or the page) can't leak a secret.
///
/// Shape: `jobtrigger://app/pair?url=<server>&name=<label>&username=<user>`.
/// Both platforms already register the `jobtrigger` scheme with host `app`
/// (US-JX-19), so this needs no new permission and no camera package.
library;

class PairLink {
  const PairLink({
    required this.jenkinsURL,
    required this.serverName,
    this.username = '',
  });

  final String jenkinsURL;
  final String serverName;

  /// Empty when the QR didn't carry one; the form then asks for it.
  final String username;

  /// The link for a server, as the website builds it. Kept here so the app's
  /// tests can round-trip exactly what the site produces.
  static String build({
    required String jenkinsURL,
    required String serverName,
    String username = '',
  }) {
    final query = {
      'url': jenkinsURL,
      'name': serverName,
      if (username.isNotEmpty) 'username': username,
    };
    return Uri(
      scheme: 'jobtrigger',
      host: 'app',
      path: '/pair',
      queryParameters: query,
    ).toString();
  }

  /// The link in a scanned QR, or null when it isn't a pairing link.
  static PairLink? fromUri(Uri uri) {
    if (uri.scheme != 'jobtrigger' || uri.host != 'app') return null;
    if (!uri.path.endsWith('/pair')) return null;
    return fromQuery(uri.queryParameters);
  }

  /// A pairing link from the parameters the router received. Null when the
  /// code didn't carry both a URL and a name, so a half-written QR (or a
  /// hand-typed link) can't open a form with nothing in it.
  static PairLink? fromQuery(Map<String, String> query) {
    final url = (query['url'] ?? '').trim();
    final name = (query['name'] ?? '').trim();
    if (url.isEmpty || name.isEmpty) return null;
    return PairLink(
      jenkinsURL: url,
      serverName: name,
      username: (query['username'] ?? '').trim(),
    );
  }
}
