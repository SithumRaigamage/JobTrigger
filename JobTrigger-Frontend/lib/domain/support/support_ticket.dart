import 'support_area.dart';
import 'support_category.dart';
import 'support_impact.dart';

/// P25-05: one filed report, as the app sees it. The backend owns the text;
/// `status` is `open` | `triaged` | `closed`. P31 adds optional areas, an
/// impact and a screenshot count — never the image bytes themselves.
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.category,
    required this.subject,
    required this.message,
    required this.status,
    this.areas = const [],
    this.impact = SupportImpact.minor,
    this.screenshotCount = 0,
    this.createdAt,
  });

  final String id;
  final SupportCategory? category;
  final String subject;
  final String message;
  final String status;
  final List<SupportArea> areas;
  final SupportImpact impact;
  final int screenshotCount;
  final DateTime? createdAt;

  SupportTicket copyWith({
    List<SupportArea>? areas,
    SupportImpact? impact,
    int? screenshotCount,
  }) => SupportTicket(
    id: id,
    category: category,
    subject: subject,
    message: message,
    status: status,
    areas: areas ?? this.areas,
    impact: impact ?? this.impact,
    screenshotCount: screenshotCount ?? this.screenshotCount,
    createdAt: createdAt,
  );

  /// What the reports list shows: never the raw enum value.
  String get statusLabel => switch (status) {
    'open' => 'Sent',
    'triaged' => 'In review',
    'closed' => 'Closed',
    _ => 'Sent',
  };
}
