import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sabbath_app/spa/suncal.dart';
import 'package:sabbath_app/utility/appdrawer.dart';
import 'package:sabbath_app/utility/location_helper.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String latitude = "";
  String longitude = "";
  late FlutterLocalNotificationsPlugin notificationPlugin;
  bool testingMode = true;
  final Map<int, bool> reminderTimes = {
    10: false,
    30: false,
    36: false,
    60: false,
    487: false,
  };

  @override
  void initState() {
    super.initState();
    notificationPlugin = FlutterLocalNotificationsPlugin();
    // _testSoundNow();
    _initNotification().then((_) {
      // Only after notification/timezone setup is complete
      _loadSavedReminders();
      _updateTimes();
    });
  }

  // Future<void> _testSoundNow() async {
  //   const AndroidNotificationDetails androidDetails =
  //       AndroidNotificationDetails(
  //         'sabbath_reminders_channel',
  //         'Sabbath Reminders',
  //         playSound: true,
  //         sound: RawResourceAndroidNotificationSound('notifications'),
  //       );

  //   const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
  //     sound: 'notification.caf',
  //   );

  //   await notificationPlugin.show(
  //     999, // Unique ID for test
  //     '🔔 Sound Test',
  //     'You should hear a notification sound',
  //     const NotificationDetails(android: androidDetails, iOS: iosDetails),
  //   );
  // }

  Future<void> _initNotification() async {
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

      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  void _updateTimes() async {
    Position? position = await LocationHelper.getCurrentLocation(context);
    if (position != null) {
      setState(() {
        latitude = position.latitude.toString();
        longitude = position.longitude.toString();
      });
    }
  }

  Future<void> _loadSavedReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTimes = prefs.getStringList('sabbath_reminders') ?? [];

    setState(() {
      for (final timeStr in savedTimes) {
        final time = int.tryParse(timeStr);
        if (time != null && reminderTimes.containsKey(time)) {
          reminderTimes[time] = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Add this key
      drawer: AppDrawer(appTitle: 'Sabbath App', appVersion: 'v1.0.0'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF4732F),
              Color(0xFFFBB13A),
              Color(0xFFFBB13A),
              Color(0xFFF4732F),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 40.0),
            child: Column(
              children: [
                _buildAppBar(),
                const SizedBox(height: 20),
                _buildTitle(),
                const SizedBox(height: 30),
                Expanded(child: _buildReminderOptions()),
                const SizedBox(height: 10),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedTimes = reminderTimes.entries
        .where((e) => e.value)
        .map((e) => e.key.toString())
        .toList();

    await prefs.setStringList('sabbath_reminders', selectedTimes);
    await _scheduleAllReminders();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selectedTimes.isEmpty
              ? 'Reminders cleared'
              : '${selectedTimes.length} reminder(s) set for both start and end',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _scheduleAllReminders() async {
    await notificationPlugin.cancelAll();
    final now = DateTime.now();
    final nextStart = _calculateNextSabbathStart(now);
    final nextEnd = _calculateNextSabbathEnd(now);

    debugPrint('⏰ Next Sabbath Start: $nextStart');
    debugPrint('⏰ Next Sabbath End: $nextEnd');

    for (final option in reminderTimes.entries.where((e) => e.value)) {
      // Schedule START reminder (Friday)
      final startReminderTime = nextStart.subtract(
        Duration(minutes: option.key),
      );
      if (startReminderTime.isAfter(now)) {
        debugPrint('🔔 START reminder at $startReminderTime');
        await _scheduleNotification(
          id: option.key * 2, // Even IDs for start
          title: 'Sabbath Starting Soon',
          body: 'Sabbath begins in ${option.key} minutes',
          scheduledTime: startReminderTime,
        );
      }

      // Schedule END reminder (Saturday)
      final endReminderTime = nextEnd.subtract(Duration(minutes: option.key));
      if (endReminderTime.isAfter(now)) {
        debugPrint('🔔 END reminder at $endReminderTime');
        await _scheduleNotification(
          id: option.key * 2 + 1, // Odd IDs for end
          title: 'Sabbath Ending Soon',
          body: 'Sabbath ends in ${option.key} minutes',
          scheduledTime: endReminderTime,
        );
      }
    }
  }

  DateTime _calculateNextSabbathStart(DateTime now) {
    // Find next Friday (even if today is Friday)
    var nextFriday = now;
    while (nextFriday.weekday != DateTime.friday) {
      nextFriday = nextFriday.add(const Duration(days: 1));
    }
    return _calculateSunsetTime(nextFriday);
  }

  DateTime _calculateNextSabbathEnd(DateTime now) {
    // Sabbath ends at sunset on Saturday (the day after Friday's start)
    final nextFriday = _calculateNextSabbathStart(now);
    final nextSaturday = nextFriday.add(const Duration(days: 1));
    return _calculateSunsetTime(nextSaturday);
  }

  DateTime _calculateSunsetTime(DateTime date) {
    try {
      double lat = double.tryParse(latitude) ?? 0.0;
      double lng = double.tryParse(longitude) ?? 0.0;

      // Validate coordinates (e.g., not 0.0, 0.0)
      if (lat == 0.0 || lng == 0.0) {
        debugPrint('⚠️ Invalid coordinates: Using fallback time (6 PM)');
        return DateTime(date.year, date.month, date.day, 18, 0);
      }

      final localOffset = date.timeZoneOffset;
      final sunsetUtc = SunCalculator.calculateSunset(
        date,
        lat,
        lng,
        localOffset,
      );

      if (sunsetUtc.year == 0) {
        debugPrint('⚠️ Sunset calculation failed: Using fallback time (6 PM)');
        return DateTime(date.year, date.month, date.day, 18, 0);
      }

      final localTime = sunsetUtc.toLocal();
      debugPrint('🌇 Sunset for ${date.toLocal()}: $localTime');
      return localTime;
    } catch (e) {
      debugPrint('❌ Error calculating sunset: $e');
      return DateTime(date.year, date.month, date.day, 18, 0);
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      // Convert the local time to the device's timezone
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'sabbath_reminders_channel',
            'Sabbath Reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('notification'),
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification.mp3',
      );

      await notificationPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'sabbath_reminder_$id',
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
            onPressed: () {
              // Use the scaffoldKey from the widget's state
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          const SizedBox(width: 40),
          // const Icon(Icons.notifications_none, color: Colors.white, size: 28),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0),
      child: Text(
        'Set reminder time for when Sabbath starts and ends',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildReminderOptions() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      itemCount: reminderTimes.length,
      itemBuilder: (context, index) {
        final key = reminderTimes.keys.elementAt(index);
        return CheckboxListTile(
          title: Text(
            '$key Minutes',
            style: const TextStyle(color: Colors.white),
          ),
          value: reminderTimes[key],
          onChanged: (bool? value) =>
              setState(() => reminderTimes[key] = value ?? false),
          activeColor: const Color(0xFFF4732F), // Selected fill color
          checkColor: Colors.white, // Checkmark color
          // Custom checkbox appearance
          checkboxShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          side: const BorderSide(color: Colors.white), // Outline color
          controlAffinity: ListTileControlAffinity.leading,
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ElevatedButton(
        onPressed: _saveReminders,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        ),
        child: const Text(
          'SAVE',
          style: TextStyle(
            color: Color(0xFFF4732F),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
