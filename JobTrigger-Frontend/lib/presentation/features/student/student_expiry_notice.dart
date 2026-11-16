import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/theme/app_colors.dart';
import '../../common_widgets/inline_alert.dart';
import '../../navigation/app_routes.dart';
import '../subscription/billing_availability.dart';
import '../subscription/entitlements_notifier.dart';
import 'student_verification_screen.dart' show formatStudentDate;

part 'student_expiry_notice.g.dart';

/// Phase 21 (SP-60): when the free student year ends within 7 days, the end
/// date; otherwise null. Only where billing is available, so a default build
/// and demo mode never see it. Computed from the plan the app already has.
@riverpod
DateTime? studentExpiryNotice(Ref ref) {
  if (!ref.watch(billingAvailableProvider)) return null;
  final snapshot = ref.watch(entitlementsNotifierProvider).value;
  return snapshot?.studentYearEndingSoon(DateTime.now());
}

/// The banner for [studentExpiryNoticeProvider]: where the year ends and what
/// happens next. Tapping opens the Subscription screen.
class StudentExpiryBanner extends ConsumerWidget {
  const StudentExpiryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final end = ref.watch(studentExpiryNoticeProvider);
    if (end == null) return const SizedBox.shrink();
    return Padding(
      key: const Key('student_expiry_banner'),
      padding: const EdgeInsets.only(top: 12),
      child: Semantics(
        button: true,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          onTap: () => context.push(AppRoutes.subscription),
          child: InlineAlert(
            icon: Icons.school_outlined,
            tone: StatusTone.unstable,
            title: 'Your student year ends soon',
            message:
                'Your free Pro year ends on ${formatStudentDate(end)}. After '
                "that you're on the Free plan. Tap to see your options.",
          ),
        ),
      ),
    );
  }
}
