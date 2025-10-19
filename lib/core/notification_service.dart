import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// TODO: Configure Firebase Cloud Messaging in Firebase Console
// TODO: For iOS, configure APNs certificates
// TODO: For Android, add google-services.json to android/app/

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize notification service
  Future<void> initialize() async {
    // Request permissions (iOS)
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      // TODO: Save token to user document in Firestore
    }

    // Listen to token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      // TODO: Update token in Firestore
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('Notification permission status: ${settings.authorizationStatus}');
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        print('Notification tapped: ${details.payload}');
      },
    );
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.notification?.title}');

    // Show local notification
    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification!.title ?? '',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'harsh_channel',
      'Harsh Notifications',
      channelDescription: 'Notifications for Harsh learning app',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    // TODO: Navigate to appropriate screen based on message data
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  // Subscribe to course notifications
  Future<void> subscribeToCourse(String courseId) async {
    await subscribeToTopic('course_$courseId');
  }

  // Send notification to topic (admin only - via Cloud Function)
  Future<void> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    // This should be done via Cloud Function for security
    // Store notification request in Firestore, Cloud Function will process it
    await _firestore.collection('notificationRequests').add({
      'topic': topic,
      'title': title,
      'body': body,
      'data': data ?? {},
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  // Schedule live class reminder
  Future<void> scheduleLiveClassReminder({
    required String courseId,
    required String title,
    required DateTime scheduledAt,
  }) async {
    // Schedule notification via Firestore
    // Cloud Function will send it at the right time
    await _firestore.collection('scheduledNotifications').add({
      'type': 'live_class_reminder',
      'courseId': courseId,
      'title': 'Live Class Starting Soon',
      'body': '$title starts in 10 minutes',
      'scheduledAt': Timestamp.fromDate(
        scheduledAt.subtract(const Duration(minutes: 10)),
      ),
      'status': 'pending',
    });
  }

  // Notify about new content upload
  Future<void> notifyNewContent({
    required String courseId,
    required String contentType, // 'lecture' or 'pdf'
    required String title,
  }) async {
    await sendNotificationToTopic(
      topic: 'course_$courseId',
      title: 'New Content Available',
      body: 'New $contentType: $title',
      data: {
        'type': 'new_content',
        'courseId': courseId,
        'contentType': contentType,
      },
    );
  }

  // Save FCM token to user document
  Future<void> saveFCMToken(String userId, String token) async {
    await _firestore.collection('users').doc(userId).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.notification?.title}');
}
