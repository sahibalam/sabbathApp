import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:device_info_plus/device_info_plus.dart';

class NotiService {
  NotiService._privateConstructor();
  static final NotiService _instance = NotiService._privateConstructor();
  factory NotiService() => _instance;

  final FlutterLocalNotificationsPlugin notificationPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initNotification() async {
    if (_isInitialized) return;

    try {
      // Request notification permission
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        debugPrint('Notification permission not granted');
        return;
      }

      // Android-specific permissions
      if (Platform.isAndroid) {
        // Battery optimization
        final batteryStatus =
            await Permission.ignoreBatteryOptimizations.status;
        if (!batteryStatus.isGranted) {
          await Permission.ignoreBatteryOptimizations.request();
        }

        // For Android 12+ (API 31+)
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 31) {
          await Permission.scheduleExactAlarm.request();
        }
      }

      // Timezone initialization
      tz.initializeTimeZones();
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));

      // Notification plugin initialization
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(android: androidSettings, iOS: iosSettings);

      await notificationPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification tapped: ${details.payload}');
        },
      );

      // ✅ Create notification channel for Android
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'sabbath_reminders_channel',
          'Sabbath Reminders',
          description: 'Channel for Sabbath reminders',
          importance: Importance.high,
        );

        await notificationPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'sabbath_reminders_channel',
        'Sabbath Reminders',
        channelDescription: 'Channel for Sabbath reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        sound: RawResourceAndroidNotificationSound('notification'),
        fullScreenIntent: true, // Important for showing while locked
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> showInstantNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    return notificationPlugin.show(id, title, body, notificationDetails());
  }

  Future<void> scheduleReminder({
    int id = 2,
    required String title,
    required String body,
    required Duration delay,
    // required int hour,
    // required int minute,
    // Duration? delay,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      // var scheduledDate = tz.TZDateTime(
      //   tz.local,
      //   now.year,
      //   now.month,
      //   now.day,
      //   hour,
      //   minute,
      // );
      final scheduledDate = now.add(delay);

      debugPrint('Scheduling notification for: $scheduledDate');

      // Cancel any existing notification with same ID
      await notificationPlugin.cancel(id);

      await notificationPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'Reminder Payload',
      );

      debugPrint('Notification scheduled successfully');
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await notificationPlugin.cancelAll();
  }
}
