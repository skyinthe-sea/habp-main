// lib/core/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'insight_service.dart';

/// Service for managing daily reminder notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final InsightService _insightService = InsightService();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) async {
        debugPrint('🔔 Notification tapped: ${details.payload}');
        if (details.payload == 'open_quick_add') {
          // This will be handled in main.dart
          debugPrint('📱 Opening quick add dialog from notification');
        }
      },
    );

    _isInitialized = true;
    debugPrint('✅ Notification service initialized');
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    // iOS permissions
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final result = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }

    // Android 13+ requires runtime permission
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  /// Schedule daily notification at 9 PM
  Future<void> scheduleDailyNotification() async {
    await initialize();

    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      debugPrint('⚠️ Notification permission denied');
      return;
    }

    // Cancel any existing scheduled notifications
    await _notifications.cancelAll();

    // Schedule notification for 9 PM every day
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      21, // 9 PM
      0,
      0,
    );

    // If 9 PM has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    debugPrint('📅 Scheduling daily notification for: $scheduledDate');

    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      '하루 마감 리마인더',
      channelDescription: '매일 저녁 9시에 오늘의 소비를 기록하도록 알려드립니다',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/launcher_icon',
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      1, // notification id
      '💰 하루 마감 시간이에요',
      '오늘의 소비를 기록해볼까요?',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at same time
      payload: 'open_quick_add',
    );

    debugPrint('✅ Daily notification scheduled successfully');
  }

  /// Send immediate notification with insight
  Future<void> sendInsightNotification() async {
    await initialize();

    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      debugPrint('⚠️ Notification permission denied');
      return;
    }

    // Generate insight message
    final insight = await _insightService.generateDailyInsight();
    final hasRecorded = await _insightService.hasRecordedToday();

    // Determine notification title and body based on activity
    String title;
    String body;
    String payload;

    if (hasRecorded) {
      // User has recorded transactions today - show insight
      title = '📊 오늘의 소비 인사이트';
      body = insight;
      payload = 'open_app';
    } else {
      // User hasn't recorded anything today - show reminder
      title = '💰 하루 마감 시간이에요';
      body = insight; // Will be "오늘의 소비를 기록해볼까요?"
      payload = 'open_quick_add';
    }

    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      '하루 마감 리마인더',
      channelDescription: '매일 저녁 9시에 오늘의 소비를 기록하도록 알려드립니다',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
      icon: '@mipmap/launcher_icon',
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );

    debugPrint('✅ Insight notification sent: $body');
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ All scheduled notifications cancelled');
  }

  /// Check if notification is scheduled
  Future<bool> isNotificationScheduled() async {
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    return pendingNotifications.isNotEmpty;
  }

  /// Get next scheduled notification time
  Future<DateTime?> getNextScheduledTime() async {
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    if (pendingNotifications.isEmpty) return null;

    // Since we're using daily repeats at 9 PM,
    // calculate next occurrence
    final now = DateTime.now();
    var nextTime = DateTime(now.year, now.month, now.day, 21, 0, 0);

    if (nextTime.isBefore(now)) {
      nextTime = nextTime.add(const Duration(days: 1));
    }

    return nextTime;
  }
}
