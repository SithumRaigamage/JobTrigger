import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/jenkins_view.dart';
import '../settings/active_server_notifier.dart';

part 'views_notifier.g.dart';

/// US-JX-17: the active server's views. Additive: if they can't be loaded,
/// Home simply shows no picker.
@riverpod
Future<List<JenkinsView>> jenkinsViews(Ref ref) async {
  final result = await ref.watch(jenkinsRepositoryProvider).fetchViews();
  return switch (result) {
    Ok(:final value) => value,
    Err() => const <JenkinsView>[],
  };
}

/// US-JX-17: the view Home lists, as its URL; null means the primary view
/// (the plain root). Persisted per server, like pins.
@riverpod
class SelectedViewNotifier extends _$SelectedViewNotifier {
  String? _serverId;

  String get _key => 'selected_view_$_serverId';

  @override
  String? build() {
    _serverId = ref.watch(
      activeServerNotifierProvider.select((server) => server?.id),
    );
    if (_serverId != null) _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (ref.mounted && stored != null) state = stored;
  }

  Future<void> select(JenkinsView view) async {
    state = view.isPrimary ? null : view.url;
    final prefs = await SharedPreferences.getInstance();
    if (state == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, state!);
    }
  }
}
