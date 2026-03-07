import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// ─── Palette ────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF070E1A);
  static const card = Color(0xFF111E33);
  static const surface = Color(0xFF162040);
  static const border = Color(0xFF1E3050);
  static const gold = Color(0xFFD4A843);
  static const goldLt = Color(0xFFF5D078);
  static const green = Color(0xFF1DB954);
  static const red = Color(0xFFE74C3C);
  static const blue = Color(0xFF3D8BF8);
  static const txt = Color(0xFFF0F4FF);
  static const muted = Color(0xFF8A9BB5);
  static const dim = Color(0xFF2A3A55);
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _hasNotificationPermission = false;
  bool _isLoading = true;
  final List<Map<String, dynamic>> _notifications = [];

  late final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _checkNotificationPermission();
    _loadSampleNotifications();
  }

  Future<void> _initializeNotifications() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(settings: initSettings);
  }

  Future<void> _checkNotificationPermission() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      setState(() {
        _hasNotificationPermission = status.isGranted;
        _isLoading = false;
      });
    } else {
      // For iOS, we'll check differently
      setState(() {
        _hasNotificationPermission = true; // iOS handles this differently
        _isLoading = false;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    setState(() => _isLoading = true);

    if (Theme.of(context).platform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      setState(() {
        _hasNotificationPermission = status.isGranted;
        _isLoading = false;
      });

      if (status.isGranted) {
        _showPermissionGrantedSnackbar();
        _showWelcomeNotification();
      } else if (status.isPermanentlyDenied) {
        _showPermissionDeniedDialog();
      }
    } else {
      // For iOS
      final settings = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      setState(() {
        _hasNotificationPermission = settings ?? false;
        _isLoading = false;
      });

      if (settings == true) {
        _showPermissionGrantedSnackbar();
        _showWelcomeNotification();
      }
    }
  }

  void _showPermissionGrantedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Notifications enabled successfully!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _C.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _C.border),
        ),
        title: const Text(
          'Open Settings',
          style: TextStyle(color: _C.txt, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Notifications are blocked. Please enable them in app settings to stay updated.',
          style: TextStyle(color: _C.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: _C.muted),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.gold,
              foregroundColor: _C.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _showWelcomeNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'welcome_channel',
      'Welcome Notifications',
      channelDescription: 'Channel for welcome notifications',
      importance: Importance.high,
      priority: Priority.high,
      color: _C.gold,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'Welcome to Notifications! 🎉',
      body: 'You\'ll now receive updates about games, results, and promotions.',
      notificationDetails: details,
    );
  }

  Future<void> _showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel for test notifications',
      importance: Importance.high,
      priority: Priority.high,
      color: _C.gold,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '🎯 New Game Alert',
      body: 'Check out the latest Single Pana game! High winning chances.',
      notificationDetails: details,
    );

    // Add to local list
    setState(() {
      _notifications.insert(0, {
        'title': '🎯 New Game Alert',
        'body': 'Check out the latest Single Pana game! High winning chances.',
        'time': DateTime.now(),
        'read': false,
      });
    });
  }

  void _loadSampleNotifications() {
    // Sample notifications for demo
    _notifications.addAll([
      {
        'title': '🏆 Result Declared',
        'body': 'Single Pana Open result is out for Market 101',
        'time': DateTime.now().subtract(const Duration(hours: 2)),
        'read': true,
      },
      {
        'title': '💰 Winning Credited',
        'body': 'Your winning amount of ₹500 has been credited',
        'time': DateTime.now().subtract(const Duration(hours: 5)),
        'read': true,
      },
      {
        'title': '⚡ Special Offer',
        'body': 'Get 10% bonus on your next bid! Limited time offer.',
        'time': DateTime.now().subtract(const Duration(days: 1)),
        'read': false,
      },
    ]);
  }

  String _getTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }

  void _markAsRead(int index) {
    setState(() {
      _notifications[index]['read'] = true;
    });
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _C.border),
        ),
        title: const Text(
          'Clear All Notifications?',
          style: TextStyle(color: _C.txt, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: _C.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: _C.muted),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_C.gold),
                strokeWidth: 3,
              ),
            )
          : !_hasNotificationPermission
          ? _buildPermissionRequest()
          : _notifications.isEmpty
          ? _buildEmptyNotifications()
          : _buildNotificationsList(),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _C.bg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.border),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _C.txt,
            size: 15,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Notifications',
        style: TextStyle(
          color: _C.txt,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        if (_notifications.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.border),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _C.red,
                  size: 18,
                ),
              ),
              onPressed: _clearAllNotifications,
              tooltip: 'Clear All',
            ),
          ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border),
              ),
              child: const Icon(
                Icons.add_alert_rounded,
                color: _C.gold,
                size: 18,
              ),
            ),
            onPressed: _showTestNotification,
            tooltip: 'Send Test Notification',
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.border.withOpacity(0.5)),
      ),
    );
  }

  // ─── Permission Request Screen ─────────────────────────────
  Widget _buildPermissionRequest() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.gold.withOpacity(0.2), _C.gold.withOpacity(0.05)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: _C.gold.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: _C.gold,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Stay Updated',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _C.txt,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Get instant alerts for game results, winning credits, and special offers',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _C.muted, height: 1.4),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _requestNotificationPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.gold,
                foregroundColor: _C.bg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Enable Notifications',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _hasNotificationPermission = true; // Skip for demo
                });
              },
              child: Text(
                'Skip for now',
                style: TextStyle(color: _C.muted.withOpacity(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty Notifications ───────────────────────────────────
  Widget _buildEmptyNotifications() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _C.gold.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: _C.gold.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: _C.gold,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'All Caught Up!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _C.txt,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "You don't have any notifications at the moment. We'll notify you when something arrives.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _C.muted, height: 1.4),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _showTestNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.card,
                foregroundColor: _C.gold,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: _C.border),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Send Test Notification',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Notifications List ────────────────────────────────────
  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification, index);
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final isRead = notification['read'] as bool;
    final time = notification['time'] as DateTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: isRead ? _C.card : _C.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _markAsRead(index),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRead ? _C.border : _C.gold.withOpacity(0.3),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _C.gold.withOpacity(isRead ? 0.1 : 0.2),
                        _C.gold.withOpacity(isRead ? 0.05 : 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRead ? _C.border : _C.gold.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification['title']),
                    color: isRead ? _C.muted : _C.gold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                          color: isRead ? _C.muted : _C.txt,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['body'],
                        style: TextStyle(
                          fontSize: 13,
                          color: isRead ? _C.muted.withOpacity(0.8) : _C.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getTimeAgo(time),
                        style: TextStyle(
                          fontSize: 11,
                          color: _C.gold.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Unread indicator
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _C.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String title) {
    if (title.contains('🏆') || title.contains('Result')) {
      return Icons.emoji_events_rounded;
    } else if (title.contains('💰') || title.contains('Winning')) {
      return Icons.account_balance_wallet_rounded;
    } else if (title.contains('⚡') || title.contains('Offer')) {
      return Icons.local_offer_rounded;
    } else if (title.contains('🎯') || title.contains('Game')) {
      return Icons.games_rounded;
    } else {
      return Icons.notifications_rounded;
    }
  }
}
