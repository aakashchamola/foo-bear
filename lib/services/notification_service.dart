import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  static Future<void> initialize() async {
    // Request notification permissions
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Get initial message if app was launched from notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // Request notification permissions
  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (kDebugMode) {
      print('Notification permission: ${settings.authorizationStatus}');
    }
  }

  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  // Get FCM token
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  // Send love notification to partner
  static Future<void> sendLoveNotification({
    required String partnerToken,
    required String senderName,
    required String message,
  }) async {
    // In a real app, you would send this through your backend server
    // For now, we'll show a local notification as a placeholder
    await showLocalNotification(
      title: '$senderName $message',
      body: 'Tap to open the app and send love back! 💕',
      payload: 'love_notification',
    );
  }

  // Show local notification
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'love_channel',
      'Love Notifications',
      channelDescription: 'Notifications for love messages',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Love Message',
      icon: '@mipmap/ic_launcher',
      color: AppConstants.heartRed,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Handling background message: ${message.messageId}');
    }

    // Process the message and show local notification if needed
    await showLocalNotification(
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? 'You have a new message',
      payload: message.data['type'],
    );
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Handling foreground message: ${message.messageId}');
    }

    // Show local notification even when app is in foreground
    await showLocalNotification(
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? 'You have a new message',
      payload: message.data['type'],
    );
  }

  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification tapped: ${message.messageId}');
    }

    // Navigate to appropriate screen based on message type
    final type = message.data['type'];
    switch (type) {
      case 'love_button':
        // Navigate to home screen
        break;
      case 'message':
        // Navigate to chat screen
        break;
      case 'photo':
        // Navigate to gallery screen
        break;
      default:
        // Navigate to home screen
        break;
    }
  }

  // Handle local notification response
  static void _onNotificationResponse(NotificationResponse response) {
    if (kDebugMode) {
      print('Local notification tapped: ${response.payload}');
    }

    // Handle local notification tap
    final payload = response.payload;
    switch (payload) {
      case 'love_notification':
        // Navigate to home screen
        break;
      case 'message':
        // Navigate to chat screen
        break;
      default:
        // Navigate to home screen
        break;
    }
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}
