import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/widget/widget_snapshot.dart';

part 'home_widget_bridge.g.dart';

/// Writes the home-screen widget's snapshot (US-JX-23) to the store the
/// native widgets read (an iOS App Group, Android shared preferences) and
/// asks them to redraw. Behind a provider so tests can substitute it.
class HomeWidgetBridge {
  /// Must match the App Group in both iOS targets' entitlements.
  static const appGroupId = 'group.Sraig.Lab-Trigger-frontend';
  static const _key = 'snapshot';
  static const _iOSKind = 'PinnedJobsWidget';
  static const _androidProvider =
      'com.sraig.jobtrigger.PinnedJobsWidgetProvider';

  // US-SQ-WIDGET-01: pinned SonarQube projects have their own widget, with its
  // own key, so the two never overwrite each other.
  static const _sonarQubeKey = 'sonarqube_snapshot';
  static const _sonarQubeIOSKind = 'PinnedProjectsWidget';
  static const _sonarQubeAndroidProvider =
      'com.sraig.jobtrigger.PinnedProjectsWidgetProvider';

  bool _groupSet = false;

  Future<void> write(WidgetSnapshot snapshot) =>
      _save(jsonEncode(snapshot.toJson()));

  /// The pinned SonarQube projects' snapshot (`US-SQ-WIDGET-01`).
  Future<void> writeSonarQube(WidgetSnapshot snapshot) => _save(
    jsonEncode(snapshot.toJson()),
    key: _sonarQubeKey,
    iOSName: _sonarQubeIOSKind,
    androidName: _sonarQubeAndroidProvider,
  );

  /// On logout: job and project names can be sensitive (US-JX-23).
  Future<void> clear() async {
    await _save(null);
    await _save(
      null,
      key: _sonarQubeKey,
      iOSName: _sonarQubeIOSKind,
      androidName: _sonarQubeAndroidProvider,
    );
  }

  Future<void> _save(
    String? json, {
    String key = _key,
    String iOSName = _iOSKind,
    String androidName = _androidProvider,
  }) async {
    try {
      if (!_groupSet) {
        await HomeWidget.setAppGroupId(appGroupId);
        _groupSet = true;
      }
      await HomeWidget.saveWidgetData<String>(key, json);
      await HomeWidget.updateWidget(
        iOSName: iOSName,
        qualifiedAndroidName: androidName,
      );
    } on Object {
      // Best effort: no widget platform (desktop, tests), or none placed.
    }
  }
}

@Riverpod(keepAlive: true)
HomeWidgetBridge homeWidgetBridge(Ref ref) => HomeWidgetBridge();
