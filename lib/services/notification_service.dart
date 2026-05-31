import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Singleton service for managing local notifications.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  FlutterLocalNotificationsPlugin? _plugin;
  bool _isInitialized = false;

  /// Initialize the notification plugin. Call once at app startup.
  Future<void> init() async {
    if (_isInitialized) return;
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      // Initialize timezone database
      tz.initializeTimeZones();

      _plugin = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final result = await _plugin!.initialize(initSettings);
      if (result != true) {
        debugPrint('NotificationService: initialize returned $result');
        _plugin = null;
        return;
      }

      // Request notification permission on Android 13+
      if (Platform.isAndroid) {
        final androidPlugin = _plugin!.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      }

      _isInitialized = true;
      debugPrint('NotificationService: initialized successfully');
    } catch (e) {
      debugPrint('NotificationService: init failed: $e');
      _plugin = null;
      _isInitialized = false;
    }
  }

  /// Schedule a notification 1 day before [deadlineDate].
  /// [id] should be a unique integer for this notification.
  /// [courseName] is the course/folder name for context.
  /// [dateString] is a human-readable representation of the deadline.
  Future<void> scheduleReminder({
    required int id,
    required String courseName,
    required DateTime deadlineDate,
    required String dateString,
  }) async {
    if (!_isInitialized || _plugin == null) return;

    // INSTANT VIDEO DEMO TESTING: Schedule 2 seconds into the future!
    final reminderDate = DateTime.now().add(const Duration(seconds: 2));

    try {
      final tzReminderDate = tz.TZDateTime.from(reminderDate, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'unisnap_reminders',
        'Υπενθυμίσεις UniSnap',
        channelDescription: 'Υπενθυμίσεις για προθεσμίες που εντοπίστηκαν σε σαρωμένα έγγραφα',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
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

      await _plugin!.zonedSchedule(
        id,
        '📚 Υπενθύμιση: $courseName',
        'Αύριο ($dateString) λήγει η προθεσμία!',
        tzReminderDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('NotificationService: scheduled reminder for $dateString (id=$id)');
    } catch (e) {
      debugPrint('NotificationService: scheduleReminder failed: $e');
    }
  }

  /// Cancel a specific notification by [id].
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized || _plugin == null) return;
    try {
      await _plugin!.cancel(id);
    } catch (e) {
      debugPrint('NotificationService: cancelNotification failed: $e');
    }
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized || _plugin == null) return;
    try {
      await _plugin!.cancelAll();
    } catch (e) {
      debugPrint('NotificationService: cancelAll failed: $e');
    }
  }

  /// Generate a unique notification ID from course name and date.
  static int generateId(String courseName, DateTime date) {
    return '${courseName}_${date.year}_${date.month}_${date.day}'.hashCode.abs() % 2147483647;
  }
}
