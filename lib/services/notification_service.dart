import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ═══════════════════════════════════════════════════════════════
// NotificationService — works in BOTH foreground & background
//
// Foreground behaviour by platform:
//
//   Android  → Uses Importance.max + fullScreenIntent so the
//              heads-up banner always pops over the app.
//              The channel is created with HIGH importance so
//              the OS never silently downgrades it.
//
//   iOS      → presentAlert/presentBadge/presentSound = true
//              makes the banner appear even when the app is
//              open in the foreground (iOS 14+).
// ═══════════════════════════════════════════════════════════════

class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Channel constants
  static const String _channelId = 'win_channel';
  static const String _channelName = 'Win Notifications';
  static const String _channelDesc =
      'Shows a notification every time you win a bid';

  // ── Initialize ─────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;

    // Android: use the app icon as the small notification icon.
    // For a white-silhouette icon (recommended) add a drawable named
    // ic_notification to res/drawable and change '@mipmap/ic_launcher'
    // below to '@drawable/ic_notification'.
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS: presentAlert = true is the key flag that makes notifications
    // show as banners even while the app is in the foreground.
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      // Optional: handle notification tap while app is open
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // ── Create the Android channel with HIGH importance ─────
    // Must be done BEFORE showing any notification.
    // If the channel already exists this is a no-op.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            // HIGH importance = heads-up banner in foreground on Android
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: Color(0xFFD4A843), // gold LED
          ),
        );

    // ── Request permissions ─────────────────────────────────
    // Android 13+ (API 33)
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // iOS
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
    debugPrint('[NotificationService] initialized ✓');
  }

  // ── Show win notification ──────────────────────────────────
  Future<void> showWinNotification({
    required double amount,
    required String gameName,
    required String marketName,
    required String session,
  }) async {
    if (!_initialized) await initialize();

    final String title = '🎉 You Won ₹${amount.toStringAsFixed(2)}!';
    final String body =
        '$gameName · $marketName ($session)\n'
        '₹${amount.toStringAsFixed(2)} has been added to your wallet.';

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,

          // ── These two lines make it show in FOREGROUND on Android ──
          importance: Importance.max, // max = URGENT — forces heads-up banner
          priority: Priority.high,

          // ───────────────────────────────────────────────────────────
          playSound: true,
          enableVibration: true,
          enableLights: true,
          color: const Color(0xFFD4A843), // gold accent on notification bar
          ledColor: const Color(0xFFD4A843), // gold LED blink
          ledOnMs: 500,
          ledOffMs: 1000,

          // Large icon (right side of notification)
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),

          // Expandable big-text style
          styleInformation: BigTextStyleInformation(
            body,
            htmlFormatBigText: false,
            contentTitle: title,
            htmlFormatContentTitle: false,
            summaryText: 'Ekdant Game',
          ),

          // ticker = text shown in status bar when notification first appears
          ticker: '🎉 You won ₹${amount.toStringAsFixed(2)}!',

          // Show full timestamp
          showWhen: true,
          when: DateTime.now().millisecondsSinceEpoch,
        );

    // iOS: presentAlert = true shows banner even in foreground
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true, // ← key for foreground on iOS
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    // Unique ID per win so multiple wins stack instead of replacing each other
    final int notifId = DateTime.now().millisecondsSinceEpoch % 100000;

    await _plugin.show(
      id: notifId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );

    debugPrint('[NotificationService] shown id=$notifId — $title');
  }

  // ── Notification tap handler ───────────────────────────────
  void _onNotificationTap(NotificationResponse response) {
    // The app is already open when this fires (foreground tap).
    // Add navigation logic here if needed, e.g.:
    //   navigatorKey.currentState?.pushNamed('/wallet');
    debugPrint('[NotificationService] tapped id=${response.id}');
  }

  // ── Helpers ────────────────────────────────────────────────
  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> cancel(int id) => _plugin.cancel(id: id);
}
