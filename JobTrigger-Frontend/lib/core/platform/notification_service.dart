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
  );

  /// Job URLs of tapped notifications, for the app to open.
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
      payload: notification.jobUrl,
    );
  }
}

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) => NotificationService();

/// Tapped notifications' job URLs, starting the plugin on first use.
@Riverpod(keepAlive: true)
Stream<String> notificationTaps(Ref ref) async* {
  final service = ref.watch(notificationServiceProvider);
  final taps = service.taps;
  await service.initialize();
  yield* taps;
}
