import 'support_category.dart';

/// P25-05: one filed report, as the app sees it. The backend owns the text;
/// `status` is `open` | `triaged` | `closed`.
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.category,
    required this.subject,
    required this.message,
    required this.status,
    this.createdAt,
  });

  final String id;
  final SupportCategory? category;
  final String subject;
  final String message;
  final String status;
  final DateTime? createdAt;

  /// What the reports list shows: never the raw enum value.
  String get statusLabel => switch (status) {
    'open' => 'Sent',
    'triaged' => 'In review',
    'closed' => 'Closed',
    _ => 'Sent',
  };
}
