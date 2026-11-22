import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/jenkins/build_watch.dart';

part 'notification_service.g.dart';

/// A thin wrapper over the platform notification plugin (US-JX-10), behind
/// a provider so tests can substitute it.
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();
  bool _initialized = false;

  static const _channel = AndroidNotificationDetails(
    'build_results',
    'Build results',
    channelDescription: 'When a watched Jenkins build finishes',
    importance: Importance.high,
    priority: Priority.high,
    // AUD-54: on a secure lock screen Android shows "Contents hidden"
    // rather than the job and result.
    visibility: NotificationVisibility.private,
  );

  /// US-SQ-WATCH-01: its own channel, so someone who silences build results
  /// still hears about a failing quality gate (and the reverse).
  static const _gateChannel = AndroidNotificationDetails(
    'quality_gates',
    'Quality gates',
    channelDescription: 'When a watched SonarQube project fails its gate',
    importance: Importance.high,
    priority: Priority.high,
    visibility: NotificationVisibility.private,
  );

  /// US-PROMO-06: billing is its own channel too, so a user who silences
  /// build results still hears that their Pro is about to end.
  static const _billingChannel = AndroidNotificationDetails(
    'subscription',
    'Subscription',
    channelDescription: 'When Pro from a promo code is about to end',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    visibility: NotificationVisibility.private,
  );

  /// Payloads of tapped notifications, for the app to open: an in-app
  /// `jobtrigger://app/open?…` link, or a bare job URL from a notification
  /// posted before AUD-45.
  Stream<String> get taps => _taps.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is asked for explicitly, after a rationale.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _taps.add(payload);
      },
    );
    // Launched by tapping a notification while the app was closed.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if ((launch?.didNotificationLaunchApp ?? false) && payload != null) {
      _taps.add(payload);
    }
  }

  /// Asks the OS for permission (Android 13+, iOS). True if granted.
  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final granted =
        await android?.requestNotificationsPermission() ??
        await ios?.requestPermissions(alert: true, sound: true) ??
        true;
    return granted;
  }

  /// A notification whose text the caller composed (US-SQ-WATCH-01), so a
  /// gate watch doesn't have to pretend to be a build. No payload: SonarQube
  /// deep links arrive with batch 5.
  Future<void> showAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: _gateChannel,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// US-PROMO-06: whether the OS will actually show a notification right
  /// now — someone who never allowed them, or turned them off since, has not
  /// been reminded. Never prompts; false when the answer cannot be read (a
  /// platform with no such question, or a failed channel call).
  Future<bool> areNotificationsAllowed() async {
    await initialize();
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return (await ios.checkPermissions())?.isEnabled ?? false;
      }
    } on Object {
      // Unknown counts as not allowed: a reminder is never marked as shown.
    }
    return false;
  }

  /// US-PROMO-06: a billing reminder. Unlike build results it is shown while
  /// the app is open (iOS hides a foreground notification otherwise), because
  /// that is where it is read; no payload, since Profile → Subscription is a
  /// tap away. Nothing prompts for permission.
  ///
  /// Returns true only when the OS took it. False when notifications are not
  /// allowed, or the platform call failed — so the caller can leave the user
  /// un-reminded and say it in the app instead.
  Future<bool> showSubscriptionAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();
    try {
      if (!await areNotificationsAllowed()) return false;
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: _billingChannel,
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentSound: false,
          ),
        ),
      );
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> show(BuildNotification notification) async {
    await initialize();
    await _plugin.show(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(),
      ),
      payload: notification.payload,
    );
  }
}

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) => NotificationService();

/// Tapped notifications' payloads, starting the plugin on first use.
@Riverpod(keepAlive: true)
Stream<String> notificationTaps(Ref ref) async* {
  final service = ref.watch(notificationServiceProvider);
  final taps = service.taps;
  await service.initialize();
  yield* taps;
}
