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

  bool _groupSet = false;

  Future<void> write(WidgetSnapshot snapshot) =>
      _save(jsonEncode(snapshot.toJson()));

  /// On logout: job names can be sensitive (US-JX-23).
  Future<void> clear() => _save(null);

  Future<void> _save(String? json) async {
    try {
      if (!_groupSet) {
        await HomeWidget.setAppGroupId(appGroupId);
        _groupSet = true;
      }
      await HomeWidget.saveWidgetData<String>(_key, json);
      await HomeWidget.updateWidget(
        iOSName: _iOSKind,
        qualifiedAndroidName: _androidProvider,
      );
    } on Object {
      // Best effort: no widget platform (desktop, tests), or none placed.
    }
  }
}

@Riverpod(keepAlive: true)
HomeWidgetBridge homeWidgetBridge(Ref ref) => HomeWidgetBridge();
