import 'package:shared_preferences/shared_preferences.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';

/// Owner decision 2026-11-21 (US-CRED-05, US-GH-CRED-03, US-SQ-CRED-03,
/// US-WEB-18): the credential chosen on the phone is also the backend
/// default. The choice applies on the phone at once; until the backend has
/// taken it, its id is kept as *pending* and pushed again on the next
/// reload of the list. Shared by the three active-credential notifiers.
class DefaultChoiceSync {
  const DefaultChoiceSync(this.pendingKey);

  /// The `shared_preferences` key (user-scoped, cleared on logout).
  final String pendingKey;

  Future<String?> pending() async =>
      (await SharedPreferences.getInstance()).getString(pendingKey);

  Future<void> drop() async =>
      (await SharedPreferences.getInstance()).remove(pendingKey);

  /// Marks [id] pending, asks the backend to make it the default, and
  /// clears the mark once it has. True on success.
  Future<bool> push(
    String id,
    Future<Result<Object?, AppFailure>> Function(String id) switchActive,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pendingKey, id);
    final Result<Object?, AppFailure> result;
    try {
      result = await switchActive(id);
    } on Object {
      return false; // kept pending; retried on the next reload
    }
    if (result case Ok()) {
      if (prefs.getString(pendingKey) == id) await prefs.remove(pendingKey);
      return true;
    }
    return false;
  }
}

/// The credential to make active on a cold start: the one still waiting to
/// reach the backend, else the backend default, else the one saved on this
/// phone, else the first.
T? pickActive<T>(
  List<T> items, {
  required String Function(T) idOf,
  required bool Function(T) isDefault,
  String? pendingId,
  String? savedId,
}) {
  T? byId(String? id) {
    if (id == null) return null;
    for (final item in items) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  return byId(pendingId) ??
      items.where(isDefault).firstOrNull ??
      byId(savedId) ??
      items.firstOrNull;
}
