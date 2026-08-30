import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:piec/core/services/spatial_audio_engine.dart';

enum NotificationType {
  chatMessage,
  friendRequest,
  spatialRadarProximity,
  sentinelEmergency,
  convoyAlert,
}

class InAppNotificationItem {
  final String id;
  final String title;
  final String body;
  final String emoji;
  final NotificationType type;
  final String? payloadSenderId;
  final DateTime timestamp;

  InAppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.emoji = '💬',
    this.type = NotificationType.chatMessage,
    this.payloadSenderId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NotificationService extends ChangeNotifier {
  static const _notificationsKey = 'piec_notifications_enabled';
  static const _radarSoundsKey = 'piec_radar_sounds_enabled';
  static const _hapticsKey = 'piec_haptics_enabled';
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final SpatialAudioEngine _audio = SpatialAudioEngine();

  String? _fcmToken;
  bool _notificationsEnabled = true;
  bool _radarSoundsEnabled = true;
  bool _hapticsEnabled = true;

  String? get fcmToken => _fcmToken;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get radarSoundsEnabled => _radarSoundsEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  final List<InAppNotificationItem> _recentNotifications = [];
  List<InAppNotificationItem> get recentNotifications => _recentNotifications;

  // Stream controller for live in-app floating banner notifications
  final StreamController<InAppNotificationItem> _bannerStreamController =
      StreamController<InAppNotificationItem>.broadcast();
  Stream<InAppNotificationItem> get bannerStream => _bannerStreamController.stream;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      _radarSoundsEnabled = prefs.getBool(_radarSoundsKey) ?? true;
      _hapticsEnabled = prefs.getBool(_hapticsKey) ?? true;
      // 1. Request Apple iOS & Android 13+ Notification Permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      _notificationsEnabled =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint('FCM Notification permission status: ${settings.authorizationStatus}');

      // 2. Get Device FCM Token
      _fcmToken = await _fcm.getToken();
      debugPrint('Device FCM Token: $_fcmToken');

      // 3. Listen to Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null && _notificationsEnabled) {
          showInAppBanner(
            title: notification.title ?? 'PieC Notification',
            body: notification.body ?? '',
            emoji: '💬',
            type: NotificationType.chatMessage,
          );
        }
      });

      // 4. Handle Notification Tap when App is in Background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification clicked in background: ${message.data}');
      });
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
    notifyListeners();
  }

  // Trigger floating In-App notification banner (Dynamic Island / Head-Up Alert)
  void showInAppBanner({
    required String title,
    required String body,
    String emoji = '💬',
    NotificationType type = NotificationType.chatMessage,
    String? senderId,
  }) {
    if (!_notificationsEnabled) return;

    if (_radarSoundsEnabled) {
      _audio.playNotificationChime();
    }

    final item = InAppNotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      emoji: emoji,
      type: type,
      payloadSenderId: senderId,
    );

    _recentNotifications.insert(0, item);
    if (_recentNotifications.length > 30) {
      _recentNotifications.removeLast();
    }

    _bannerStreamController.add(item);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool val) async {
    _notificationsEnabled = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, val);
  }

  Future<void> setRadarSoundsEnabled(bool val) async {
    _radarSoundsEnabled = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_radarSoundsKey, val);
  }

  Future<void> setHapticsEnabled(bool val) async {
    _hapticsEnabled = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsKey, val);
  }

  @override
  void dispose() {
    _bannerStreamController.close();
    super.dispose();
  }
}
