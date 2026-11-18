import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'support_category.dart';
import 'support_diagnostics.dart';
import 'support_ticket.dart';

/// P25-05: the app's side of `POST/GET /api/support/tickets`.
abstract class SupportRepository {
  Future<Result<SupportTicket, AppFailure>> submit({
    required SupportCategory category,
    required String subject,
    required String message,
    String? replyEmail,
    SupportDiagnostics? diagnostics,
  });

  Future<Result<List<SupportTicket>, AppFailure>> fetchMine();
}
