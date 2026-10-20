/// Plain text from Jenkins' HTML build and job descriptions (US-JX-14).
/// The app never renders server-supplied HTML: that would be an injection
/// surface, and a phone doesn't need the markup. Tags are dropped,
/// `<br>`/`</p>` become line breaks, and common entities are decoded.
String htmlToPlainText(String html) {
  var text = html
      .replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(
        RegExp(r'</\s*(p|div|li|h[1-6])\s*>', caseSensitive: false),
        '\n',
      )
      .replaceAll(RegExp(r'<[^>]*>'), '');
  const entities = {
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&nbsp;': ' ',
  };
  for (final MapEntry(:key, :value) in entities.entries) {
    text = text.replaceAll(key, value);
  }
  // Last, so `&amp;lt;` decodes to the literal `&lt;`, not `<`.
  text = text.replaceAll('&amp;', '&');
  return text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}
