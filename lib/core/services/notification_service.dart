import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Handles FCM token management, local notification display,
/// and sending order-status notifications to users via Firestore.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _channelKey = 'smartcanteen_orders';
  static const _channelName = 'Pesanan SmartCanteen';
  static const _channelDesc = 'Notifikasi update status pesanan';

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Call once from main() AFTER Firebase.initializeApp().
  Future<void> initialize() async {
    // 1. Init awesome_notifications channels
    await AwesomeNotifications().initialize(
      null, // use default app icon
      [
        NotificationChannel(
          channelKey: _channelKey,
          channelName: _channelName,
          channelDescription: _channelDesc,
          defaultColor: const Color(0xFF7C3AED),
          ledColor: const Color(0xFF7C3AED),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
      ],
      debug: kDebugMode,
    );

    // 2. Request permission (iOS + Android 13+)
    await _requestPermission();

    // 3. Handle FCM messages received while app is in FOREGROUND
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 4. Handle taps on notifications when app was in BACKGROUND (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // 5. Handle message that launched the app from TERMINATED state
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _onNotificationTap(initial);
  }

  Future<void> _requestPermission() async {
    if (kIsWeb) return;
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    // Also request from awesome_notifications (needed on Android 13+)
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  // ── Token management ───────────────────────────────────────────────────────

  /// Get current device FCM token. Returns null on web or if unavailable.
  Future<String?> getToken() async {
    if (kIsWeb) return null;
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('FCM getToken error: $e');
      return null;
    }
  }

  /// Save/update the FCM token for a user in Firestore.
  /// Call this after login with the authenticated userId.
  Future<void> saveTokenForUser(String userId) async {
    try {
      final token = await getToken();
      if (token == null) return;

      await _db.collection('users').doc(userId).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'platform': _platform,
        },
        SetOptions(merge: true),
      );
      debugPrint('FCM token saved for user $userId');

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) async {
        await _db.collection('users').doc(userId).update({
          'fcmToken': newToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM token refreshed for user $userId');
      });
    } catch (e) {
      debugPrint('saveTokenForUser error: $e');
    }
  }

  /// Remove FCM token on logout (prevent ghost notifications).
  Future<void> clearTokenForUser(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('clearTokenForUser error: $e');
    }
  }

  String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  // ── Send notification (admin → user) ──────────────────────────────────────

  /// Store a notification document in Firestore AND show a local notification
  /// on this device if we are on the user's device.
  ///
  /// This is the "server-less" approach: instead of a Cloud Function, the admin
  /// app writes to `notifications/{userId}/messages` and the user app's FCM
  /// listener picks it up via Firestore onSnapshot or local push.
  Future<void> sendOrderStatusNotification({
    required String userId,
    required String orderId,
    required String orderShortId,
    required String newStatus,
  }) async {
    final title = _titleForStatus(newStatus);
    final body = _bodyForStatus(newStatus, orderShortId);

    try {
      // 1. Persist notification to Firestore so user sees it in notification center
      await _db
          .collection('notifications')
          .doc(userId)
          .collection('messages')
          .add({
        'userId': userId,
        'orderId': orderId,
        'title': title,
        'body': body,
        'status': newStatus,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'order_status',
      });

      // 2. Update unread badge count on user doc
      await _db.collection('users').doc(userId).set(
        {'unreadNotifications': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('sendOrderStatusNotification error: $e');
    }
  }

  /// Broadcast a custom notification to all users.
  Future<bool> broadcastNotification({
    required String title,
    required String body,
  }) async {
    try {
      final usersSnap = await _db.collection('users').get();
      final batch = _db.batch();

      for (var doc in usersSnap.docs) {
        final userId = doc.id;
        final data = doc.data();
        if (data['role'] == 'admin') continue;

        final msgRef = _db
            .collection('notifications')
            .doc(userId)
            .collection('messages')
            .doc();

        batch.set(msgRef, {
          'userId': userId,
          'title': title,
          'body': body,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'type': 'broadcast',
        });

        final userRef = _db.collection('users').doc(userId);
        batch.set(userRef, {
          'unreadNotifications': FieldValue.increment(1)
        }, SetOptions(merge: true));
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('broadcastNotification error: $e');
      return false;
    }
  }

  // ── Show local notification ────────────────────────────────────────────────

  /// Display a local notification using awesome_notifications.
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: _channelKey,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        payload: payload != null ? {'data': payload} : null,
        autoDismissible: true,
      ),
    );
  }

  // ── Mark notifications as read ─────────────────────────────────────────────

  Future<void> markAllAsRead(String userId) async {
    try {
      final snap = await _db
          .collection('notifications')
          .doc(userId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      await _db
          .collection('users')
          .doc(userId)
          .update({'unreadNotifications': 0});
    } catch (e) {
      debugPrint('markAllAsRead error: $e');
    }
  }

  Future<void> markAsRead(String userId, String messageId) async {
    try {
      await _db
          .collection('notifications')
          .doc(userId)
          .collection('messages')
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  // ── Stream for notification center ────────────────────────────────────────

  Stream<QuerySnapshot> streamNotifications(String userId) {
    return _db
        .collection('notifications')
        .doc(userId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<int> streamUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .doc(userId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ── FCM message handlers ───────────────────────────────────────────────────

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('FCM foreground: ${message.notification?.title}');
    final n = message.notification;
    if (n != null) {
      showLocalNotification(
        title: n.title ?? 'SmartCanteen',
        body: n.body ?? '',
        payload: message.data['orderId'],
      );
    }
  }

  void _onNotificationTap(RemoteMessage message) {
    debugPrint('FCM tap: ${message.data}');
    // Deep-link handled by NavigationService or main navigator key
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _titleForStatus(String status) {
    switch (status) {
      case 'processing':
        return '🍳 Pesanan Diproses';
      case 'ready':
        return '✅ Pesanan Siap Diambil!';
      case 'completed':
        return '🎉 Pesanan Selesai';
      case 'cancelled':
        return '❌ Pesanan Dibatalkan';
      default:
        return '📦 Update Pesanan';
    }
  }

  String _bodyForStatus(String status, String shortId) {
    switch (status) {
      case 'processing':
        return 'Pesanan #$shortId sedang dimasak. Harap tunggu sebentar ya!';
      case 'ready':
        return 'Pesanan #$shortId sudah siap! Silakan ambil di kantin.';
      case 'completed':
        return 'Terima kasih! Pesanan #$shortId telah selesai. Jangan lupa beri rating 😊';
      case 'cancelled':
        return 'Maaf, pesanan #$shortId dibatalkan. Hubungi CS jika ada pertanyaan.';
      default:
        return 'Status pesanan #$shortId telah diperbarui.';
    }
  }
}

// ── Background handler (top-level function, required by FCM) ─────────────────

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized in isolate if using firebase_core
  debugPrint('FCM background: ${message.notification?.title}');
}
