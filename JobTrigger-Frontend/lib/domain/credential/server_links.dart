/// P19-06: the web page "Open Jenkins link" opens in the browser — a
/// server's own address, or a folder's page inside it. Null when [url]
/// isn't a usable `http(s)` address, so the caller can say so instead of
/// handing the OS something it can't open.
Uri? jenkinsWebUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  // Dart parses `exa mple.com` into the host `exa%20mple.com`: not a host.
  if (uri == null || uri.host.isEmpty || uri.host.contains('%')) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return uri;
}
