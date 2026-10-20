import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../settings/active_server_notifier.dart';

part 'pinned_jobs_notifier.g.dart';

/// A job pinned to the top of Home (US-JX-11). URL and label only — both
/// non-secret, so `shared_preferences` is the right store (`CLAUDE.md` §7).
class PinnedJob {
  const PinnedJob({required this.url, required this.label});

  factory PinnedJob.fromJson(Map<String, dynamic> json) =>
      PinnedJob(url: json['url'] as String, label: json['label'] as String);

  final String url;
  final String label;

  Map<String, String> toJson() => {'url': url, 'label': label};
}

/// Pins for the active server, in the order they were pinned. Rebuilt
/// (and reloaded) whenever the active server changes: pins belong to a
/// server, not the app.
@riverpod
class PinnedJobsNotifier extends _$PinnedJobsNotifier {
  String? _serverId;

  String get _key => 'pinned_jobs_$_serverId';

  @override
  List<PinnedJob> build() {
    _serverId = ref.watch(
      activeServerNotifierProvider.select((server) => server?.id),
    );
    if (_serverId != null) _load();
    return const [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || !ref.mounted) return;
    try {
      state = [
        for (final item in jsonDecode(raw) as List<dynamic>)
          PinnedJob.fromJson(item as Map<String, dynamic>),
      ];
    } on FormatException {
      // Corrupt entry: start clean rather than crash Home.
      await prefs.remove(_key);
    }
  }

  bool isPinned(String url) => state.any((pin) => pin.url == url);

  /// Pins [job], or unpins it if already pinned. Returns true if pinned.
  Future<bool> toggle(JenkinsJob job) async {
    final pinned = isPinned(job.url);
    state = pinned
        ? [
            for (final pin in state)
              if (pin.url != job.url) pin,
          ]
        : [...state, PinnedJob(url: job.url, label: job.label)];
    await _save();
    return !pinned;
  }

  Future<void> unpin(String url) async {
    state = [
      for (final pin in state)
        if (pin.url != url) pin,
    ];
    await _save();
  }

  Future<void> _save() async {
    if (_serverId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final pin in state) pin.toJson()]),
    );
  }
}

/// A pinned job's live status: the job, or null when it no longer exists
/// (404), so Home can offer to remove the stale pin.
@riverpod
Future<JenkinsJob?> pinnedJobStatus(Ref ref, String url) async {
  final result = await ref.watch(jenkinsRepositoryProvider).fetchJobDetail(url);
  return switch (result) {
    Ok(:final value) => value,
    Err(error: NotFoundFailure()) => null,
    Err(:final error) => throw error,
  };
}
