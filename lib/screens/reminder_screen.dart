import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sabbath_app/spa/suncal.dart';
import 'package:sabbath_app/utility/appdrawer.dart';
import 'package:sabbath_app/utility/location_helper.dart';

import 'package:sabbath_app/services/alarm_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Add these imports for background service
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/services.dart';

// Background notification response handler
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse details) async {
  debugPrint('🔔 Background notification received: ${details.payload}');
  
  if (details.payload == 'sabbath_notification') {
    // Initialize audio player for background playback
    final player = AudioPlayer();
    
    try {
      // Configure for background playback
      await player.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.allowBluetooth,
              AVAudioSessionOptions.allowBluetoothA2DP,
            },
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );

      await player.setVolume(1.0);
      await player.setReleaseMode(ReleaseMode.stop);
      
      debugPrint('🔊 Playing background notification sound');
      await player.play(AssetSource('sounds/notification.mp3'));
      
      // Clean up after playback
      player.onPlayerComplete.listen((_) {
        player.dispose();
        debugPrint('✅ Background notification sound completed');
      });
      
    } catch (e) {
      debugPrint('❌ Background notification error: $e');
      player.dispose();
    }
  }
}

// Background isolate entry point for alarm service
@pragma('vm:entry-point')
void alarmBackgroundHandler(dynamic message) {
  WidgetsFlutterBinding.ensureInitialized();
  
  final ReceivePort port = ReceivePort();
  IsolateNameServer.registerPortWithName(port.sendPort, 'alarm_isolate');
  
  port.listen((dynamic data) async {
    if (data == 'start_alarm') {
      // Handle background alarm logic here
      await _playBackgroundAlarm();
    } else if (data == 'stop_alarm') {
      // Stop background alarm
      await _stopBackgroundAlarm();
    }
  });
}

// Global audio player for background service
AudioPlayer? _backgroundPlayer;
Timer? _alarmTimer;

Future<void> _playBackgroundAlarm() async {
  try {
    _backgroundPlayer ??= AudioPlayer();
    
    // Configure audio session for background playback
    await _backgroundPlayer!.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.allowBluetooth,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
        ),
      ),
    );

    await _backgroundPlayer!.setVolume(1.0);
    await _backgroundPlayer!.setReleaseMode(ReleaseMode.loop);
    
    // Start playing
    await _backgroundPlayer!.play(AssetSource('sounds/notification.mp3'));
    
    // Set timer to stop after 40 seconds
    _alarmTimer?.cancel();
    _alarmTimer = Timer(const Duration(seconds: 40), () async {
      await _stopBackgroundAlarm();
    });
    
  } catch (e) {
    debugPrint('Background alarm error: $e');
  }
}

Future<void> _stopBackgroundAlarm() async {
  try {
    _alarmTimer?.cancel();
    await _backgroundPlayer?.stop();
    await _backgroundPlayer?.dispose();
    _backgroundPlayer = null;
  } catch (e) {
    debugPrint('Error stopping background alarm: $e');
  }
}

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

bool testSebastianMode = false; // Set this to false for production
static const Map<String, String> sebastianCoords = {
  'lat': '47.6588',      // Spokane latitude
  'lng': '-117.4260',    // Spokane longitude
  'timezone': 'America/Los_Angeles' // Spokane is in Pacific Time
};

  bool _isLoadingLocation = false;
  late FlutterLocalNotificationsPlugin notificationPlugin;
  bool testingMode = true;
  final Map<int, bool> reminderTimes = {
    10: false,
    20: false,
    30: false,
    60: false,
    6851: false,
  };
  
  int _alarmDurationSeconds = 40; // Default alarm duration

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAlarm = false;
  final AlarmService _alarmService = AlarmService();
  Timer? _alarmStopTimer;
  bool _showAlarmDialog = false;

  // Enhanced alarm system with background support
  Future<void> _playExtendedAlarm() async {
  if (_isPlayingAlarm) return;

  setState(() {
    _isPlayingAlarm = true;
    _showAlarmDialog = true;
  });
  
  try {
    // 1️⃣ Stop any existing playback
    await _audioPlayer.stop();
    _alarmStopTimer?.cancel();

    // 2️⃣ Configure audio session for extended playback
    await _audioPlayer.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.allowBluetooth,
            AVAudioSessionOptions.duckOthers,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );

    // 3️⃣ Set max volume and loop mode
    await _audioPlayer.setVolume(1.0);
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);

    // 4️⃣ Start playback
    await _audioPlayer.play(
      AssetSource('sounds/notification.mp3'),
      mode: PlayerMode.mediaPlayer,
    );

    // 5️⃣ Show alarm dialog for user interaction
    _showAlarmNotificationDialog();

    // 6️⃣ Auto-stop after 40 seconds
    _alarmStopTimer = Timer(const Duration(seconds: 40), () {
      _stopExtendedAlarm();
    });

    // 7️⃣ Try background service as fallback
    _startBackgroundAlarmService();

  } catch (e) {
    debugPrint('Extended alarm error: $e');
    // Fallback to short alarm
    await _playFallbackAlarm();
  }
}

void _startBackgroundAlarmService() {
  try {
    final SendPort? send = IsolateNameServer.lookupPortByName('alarm_isolate');
    send?.send('start_alarm');
  } catch (e) {
    debugPrint('Background service not available: $e');
  }

  Future<void> _stopExtendedAlarm() async {
  if (!_isPlayingAlarm) return;

  try {
    // Stop main player
    _alarmStopTimer?.cancel();
    await _audioPlayer.stop();
    
    // Stop background service
    final SendPort? send = IsolateNameServer.lookupPortByName('alarm_isolate');
    send?.send('stop_alarm');
    
    // Update UI
    if (mounted) {
      setState(() {
        _isPlayingAlarm = false;
        _showAlarmDialog = false;
      });
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  } catch (e) {
    debugPrint('Error stopping extended alarm: $e');
  }

  Future<void> _playFallbackAlarm() async {
  // Fallback method for older devices
  try {
    await _audioPlayer.setVolume(1.0);
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    
    Timer(const Duration(seconds: 40), () async {
      await _audioPlayer.stop();
      if (mounted) setState(() => _isPlayingAlarm = false);
    });
  } catch (e) {
    debugPrint('Fallback alarm error: $e');
  }

  void _showAlarmNotificationDialog() {
  if (!mounted || !_showAlarmDialog) return;
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.notifications_active, color: Color(0xFFF4732F), size: 30),
              SizedBox(width: 10),
              Text('Sabbath Reminder', style: TextStyle(color: Colors.white, fontSize: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sabbath time notification',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                backgroundColor: Colors.grey[700],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF4732F)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Alarm will stop automatically in 40 seconds',
                style: TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _stopExtendedAlarm,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF4732F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('STOP ALARM', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    },
  );
  }

  // Updated to use AlarmService for 40-second playback
  Future<void> _playAlarm() async {
  await _alarmService.startAlarm(
    title: "Sabbath Reminder",
    body: "Sabbath time!",
    durationSeconds: 40,
  );
    setState(() {}); // Refresh UI to show stop button
  }

  @override
  void initState() {
    super.initState();
    notificationPlugin = FlutterLocalNotificationsPlugin();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initNotification();
      await _alarmService.initialize(notificationPlugin);
      await _initBackgroundService();
      await _loadLastLocation();
      await _updateTimes();
      await _loadSavedReminders();
      await _loadAlarmDuration();
    });
  }

  Future<void> _initBackgroundService() async {
  try {
    // Initialize background isolate for alarm service
    await Isolate.spawn(alarmBackgroundHandler, 'init');
    debugPrint('Background alarm service initialized');
  } catch (e) {
    debugPrint('Failed to initialize background service: $e');
  }
}

  Future<void> _initNotification() async {
    try {
      // Request notification permission
      // final status = await Permission.notification.request();
      // if (!status.isGranted) {
      //   debugPrint('Notification permission not granted');
      //   return;
      // }

      // Android-specific permissions
      if (Platform.isAndroid) {
        final batteryStatus =
            await Permission.ignoreBatteryOptimizations.status;
        if (!batteryStatus.isGranted) {
          await Permission.ignoreBatteryOptimizations.request();
        }

        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 31) {
          await Permission.scheduleExactAlarm.request();
        }
      }

      // Timezone initialization
      tz.initializeTimeZones();
   if (testSebastianMode) {
        tz.setLocalLocation(tz.getLocation('America/New_York'));
        debugPrint('⚠️ TEST MODE: Using Sebastian, FL timezone (America/New_York)');
      } else {
        final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(currentTimeZone));
      }


      // Notification plugin initialization - using @mipmap/ic_stat
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_stat');

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
        onDidReceiveNotificationResponse: (details) async {
          debugPrint('📱 Notification response: ${details.payload}');
          if (details.payload == 'sabbath_notification') {
            // When sabbath notification is received, play full duration sound
            await _alarmService.playFullNotificationSound();
          } else if (details.payload == 'alarm') {
            // When notification is tapped, start the 40-second alarm
            await _alarmService.startAlarm(
              title: "Sabbath Reminder",
              body: "Sabbath time!",
              durationSeconds: _alarmDurationSeconds,
            );
          } else if (details.payload == 'stop_alarm') {
            // Stop alarm if user taps stop button
            await _alarmService.stopAlarm();
          }
        },
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
      );

      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<void> _updateTimes() async {
    if (_isLoadingLocation) return;
    setState(() => _isLoadingLocation = true);

    try {
      if (testSebastianMode) {
        // Use Sebastian coordinates for testing
        setState(() {
          latitude = sebastianCoords['lat']!;
          longitude = sebastianCoords['lng']!;
        });
        await _saveTestLocation();
      } else {
        // Normal location flow
        final position = await LocationHelper.getCurrentLocation(context);
        if (position != null && _isValidLocation(position.latitude, position.longitude)) {
          await _saveLocation(position);
          setState(() {
            latitude = position.latitude.toStringAsFixed(6);
            longitude = position.longitude.toStringAsFixed(6);
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _saveTestLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_latitude', sebastianCoords['lat']!);
    await prefs.setString('last_longitude', sebastianCoords['lng']!);
  }

  Future<void> _saveLocation(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_latitude', position.latitude);
    await prefs.setDouble('last_longitude', position.longitude);
  }

  Future<void> _loadLastLocation() async {
  final prefs = await SharedPreferences.getInstance();

  try {
    final latValue = prefs.get('last_latitude');
    final lngValue = prefs.get('last_longitude');

    double? lastLat;
    double? lastLng;

    if (latValue is double) {
      lastLat = latValue;
    } else if (latValue is String) {
      lastLat = double.tryParse(latValue);
    }

    if (lngValue is double) {
      lastLng = lngValue;
    } else if (lngValue is String) {
      lastLng = double.tryParse(lngValue);
    }

    if (lastLat != null && lastLng != null) {
      setState(() {
        latitude = lastLat!.toStringAsFixed(6);
        longitude = lastLng!.toStringAsFixed(6);
      });
    }
  } catch (e) {
    debugPrint('Error loading saved location: $e');
  }
}

  bool _isValidLocation(double lat, double lng) {
    if (lat.abs() > 90 || lng.abs() > 180) return false;
    if (lat == 0 && lng == 0) return false;
    return true;
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

  Future<void> _loadAlarmDuration() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _alarmDurationSeconds = prefs.getInt('alarm_duration_seconds') ?? 40;
    });
  }

  Future<void> _saveAlarmDuration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('alarm_duration_seconds', _alarmDurationSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(appTitle: 'Sabbath App', appVersion: 'v2.0.4'),
      floatingActionButton: _alarmService.isPlaying 
        ? FloatingActionButton.extended(
            onPressed: () async {
              await _alarmService.stopAlarm();
              setState(() {}); // Refresh UI
            },
            backgroundColor: Colors.red,
            icon: const Icon(Icons.stop, color: Colors.white),
            label: const Text('Stop Alarm', style: TextStyle(color: Colors.white)),
          )
        : null,
  body: Stack(
  children: [
    Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/sabbathback.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
    ),
    Container(
      color: Colors.black.withOpacity(0.5), // <-- Overlay layer
    ),
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Column(
          children: [
            _buildAppBar(),
            const SizedBox(height: 20),
            _buildTitle(),
                              const SizedBox(height: 30),
                  _buildAudioDurationSelector(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildReminderOptions()),
            const SizedBox(height: 10),
            _buildTestAlarmButton(),
            const SizedBox(height: 10),
            _buildSaveButton(),
          ],
        ),
      ),
    ),
  ],
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
  _alarmService.cancelAllScheduledAlarms(); // Cancel existing alarm schedules

  final now = tz.TZDateTime.now(tz.local);
  final nextStart = _calculateNextSabbathStart(now);
  final nextEnd = _calculateNextSabbathEnd(now);

  debugPrint('\n=== SABBATH REMINDER SCHEDULING ===');
  debugPrint('⏰ Current Time (Florida): ${now.toLocal()}');
  debugPrint('🕯️ Next Sabbath Start: ${nextStart.toLocal()}');
  debugPrint('🔚 Next Sabbath End: ${nextEnd.toLocal()}');

  // Only proceed if the calculated times are in the future
  if (nextStart.isBefore(now)) {
    debugPrint('⚠️ Next Sabbath start is in the past! Not scheduling reminders.');
    return;
  }

  if (nextEnd.isBefore(now)) {
    debugPrint('⚠️ Next Sabbath end is in the past! Not scheduling reminders.');
    return;
  }

  // Schedule reminders based on reminderTimes map
  for (final entry in reminderTimes.entries.where((e) => e.value)) {
    final minutes = entry.key;
    final duration = Duration(minutes: minutes);

    // Start Reminder (Friday)
    final startReminderTime = nextStart.subtract(duration);
    if (startReminderTime.isAfter(now)) {
      await _scheduleWithVerification(
        id: 'start_$minutes'.hashCode,
        title: 'Sabbath Starts Soon!',
        body: 'Sabbath begins in $minutes minutes',
        scheduledTime: startReminderTime,
      );
      // 🔔 Schedule alarm for the same time
      _alarmService.scheduleAlarm(
        scheduledTime: startReminderTime.toLocal(),
        title: 'Sabbath Starts Soon!',
        body: 'Sabbath begins in $minutes minutes',
        durationSeconds: _alarmDurationSeconds,
      );
    } else {
      debugPrint('⚠️ Start reminder $minutes minutes before is in the past');
    }

    // End Reminder (Saturday)
    final endReminderTime = nextEnd.subtract(duration);
    if (endReminderTime.isAfter(now)) {
      await _scheduleWithVerification(
        id: 'end_$minutes'.hashCode,
        title: 'Sabbath Ends Soon!',
        body: 'Sabbath ends in $minutes minutes',
        scheduledTime: endReminderTime,
      );
      // 🔔 Schedule alarm for the same time
      _alarmService.scheduleAlarm(
        scheduledTime: endReminderTime.toLocal(),
        title: 'Sabbath Ends Soon!',
        body: 'Sabbath ends in $minutes minutes',
        durationSeconds: _alarmDurationSeconds,
      );
    } else {
      debugPrint('⚠️ End reminder $minutes minutes before is in the past');
    }
  }

  // Only schedule exact notifications if they're in the future
  if (nextStart.isAfter(now)) {
    await _scheduleWithVerification(
      id: 'exact_start'.hashCode,
      title: 'Sabbath Has Started!',
      body: 'Shabbat Shalom!',
      scheduledTime: nextStart,
    );
    // 🔔 Schedule alarm for exact start time
    _alarmService.scheduleAlarm(
      scheduledTime: nextStart.toLocal(),
      title: 'Sabbath Has Started!',
      body: 'Shabbat Shalom!',
      durationSeconds: _alarmDurationSeconds,
    );
  }

  if (nextEnd.isAfter(now)) {
    await _scheduleWithVerification(
      id: 'exact_end'.hashCode,
      title: 'Sabbath Has Ended',
      body: 'Have a blessed week!',
      scheduledTime: nextEnd,
    );
    // 🔔 Schedule alarm for exact end time
    _alarmService.scheduleAlarm(
      scheduledTime: nextEnd.toLocal(),
      title: 'Sabbath Has Ended',
      body: 'Have a blessed week!',
      durationSeconds: _alarmDurationSeconds,
    );
  }

  Future<void> _scheduleWithVerification({
  required int id,
  required String title,
  required String body,
  required tz.TZDateTime scheduledTime,
}) async {
  try {
    await notificationPlugin.cancel(id);

    // Schedule the original notification (unchanged - keeps your existing system)
    await notificationPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'sabbath_channel_id',
          'Sabbath Reminders',
          channelDescription: 'Sabbath start and end reminders',
          icon: '@mipmap/ic_stat',
          color: const Color(0xFFF4732F),
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('notification'),
          enableVibration: true,
          fullScreenIntent: true,
          ongoing: true,
          visibility: NotificationVisibility.public,
          timeoutAfter: 0,
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'notification.caf',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'sabbath_notification',
      matchDateTimeComponents: null,
    );

    // Verification
    final pending = await notificationPlugin.pendingNotificationRequests();
    if (pending.any((n) => n.id == id)) {
      debugPrint('✓ Scheduled notification: $title at ${scheduledTime.toLocal()}');
    } else {
      debugPrint('✗ Failed to schedule: $title');
    }
  } catch (e) {
    debugPrint('Error scheduling: $e');
    rethrow;
  }

  tz.TZDateTime _calculateNextSabbathStart(DateTime now) {
  final location = tz.local;
  final localNow = tz.TZDateTime.from(now, location);
  
  debugPrint('\n=== Calculating Next Sabbath Start ===');
  debugPrint('Current local time: ${localNow.toLocal()}');
  debugPrint('Current weekday: ${localNow.weekday} (${_weekdayName(localNow.weekday)})');

  // Find next Friday
  var daysUntilFriday = (DateTime.friday - localNow.weekday + 7) % 7;
  var nextFriday = tz.TZDateTime(
    location,
    localNow.year,
    localNow.month,
    localNow.day + daysUntilFriday,
  );

  debugPrint('Next Friday date: ${nextFriday.toLocal()}');

  // Calculate sunset for that Friday
  var sunset = _calculateSunsetTime(nextFriday);
  
  debugPrint('Calculated sunset: ${sunset.toLocal()}');

  // If today is Friday but after sunset, use next week
  if (daysUntilFriday == 0 && localNow.isAfter(sunset)) {
    debugPrint('Today is Friday but after sunset, using next week');
    nextFriday = tz.TZDateTime(
      location,
      localNow.year,
      localNow.month,
      localNow.day + 7,
    );
    sunset = _calculateSunsetTime(nextFriday);
    debugPrint('Adjusted next Friday: ${nextFriday.toLocal()}');
    debugPrint('Adjusted sunset: ${sunset.toLocal()}');
  }
  
  return sunset;
  }

  String _weekdayName(int weekday) {
  return const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][weekday - 1];
  }

  tz.TZDateTime _calculateNextSabbathEnd(DateTime now) {
    final start = _calculateNextSabbathStart(now);
    final location = tz.local;
    
    // Get Saturday date (next day after Friday start)
    final saturdayDate = tz.TZDateTime(
      location,
      start.year,
      start.month,
      start.day + 1,
    );

    // Calculate sunset for Saturday
    final saturdaySunset = _calculateSunsetTime(saturdayDate);

    debugPrint('Saturday date: ${saturdayDate.toLocal()}');
    debugPrint('Saturday sunset: ${saturdaySunset.toLocal()}');
    
    return saturdaySunset;
  }

  tz.TZDateTime _calculateSunsetTime(tz.TZDateTime date) {
  try {
    final lat = testSebastianMode 
        ? double.parse(sebastianCoords['lat']!)
        : double.tryParse(latitude) ?? 0.0;
        
    final lng = testSebastianMode
        ? double.parse(sebastianCoords['lng']!)
        : double.tryParse(longitude) ?? 0.0;

    if (lat == 0.0 || lng == 0.0) {
      return tz.TZDateTime(date.location, date.year, date.month, date.day, 18, 0);
    }

    // Calculate sunset in UTC for the given date
    final sunsetUtc = SunCalculator.calculateSunset(
      DateTime.utc(date.year, date.month, date.day), // Use the exact date
      lat,
      lng,
      Duration.zero,
    );

    // Convert to local time in the target timezone
    final sunsetLocal = tz.TZDateTime.from(sunsetUtc, date.location);
    
    // Create a new TZDateTime with the correct date components
    return tz.TZDateTime(
      date.location,
      date.year,
      date.month,
      date.day,
      sunsetLocal.hour,
      sunsetLocal.minute,
    );
  } catch (e) {
    debugPrint("Sunset calculation error: $e");
    return tz.TZDateTime(date.location, date.year, date.month, date.day, 18, 0);
  }

  tz.TZDateTime _getNextFriday(tz.TZDateTime now) {
  final daysUntilFriday = (DateTime.friday - now.weekday + 7) % 7;
  return tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day + daysUntilFriday
  );
  }

  Widget _buildAppBar() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'REMINDER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 48), // For symmetry with IconButton size
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
        final displayText = key > 60
            ? '${(key / 60).toStringAsFixed(key % 60 == 0 ? 0 : 1)} Hour${key >= 120 ? 's' : ''}'
            : '$key Minute${key == 1 ? '' : 's'}';
        return CheckboxListTile(
          title: Text(displayText, style: const TextStyle(color: Colors.white)),
          value: reminderTimes[key],
          onChanged: (bool? value) =>
              setState(() => reminderTimes[key] = value ?? false),
          activeColor: const Color(0xFFF4732F),
          checkColor: Colors.white,
          checkboxShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          side: const BorderSide(color: Colors.white),
          controlAffinity: ListTileControlAffinity.leading,
        );
      },
    );
  }

  Widget _buildAudioDurationSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audio Duration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _alarmDurationSeconds,
                dropdownColor: const Color(0xFF2C2C2C),
                style: const TextStyle(color: Colors.white),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                isExpanded: true,
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _alarmDurationSeconds = newValue;
                    });
                    _saveAlarmDuration();
                  }
                },
                items: [
                  const DropdownMenuItem(value: 10, child: Text('10 seconds')),
                  const DropdownMenuItem(value: 20, child: Text('20 seconds')),
                  const DropdownMenuItem(value: 30, child: Text('30 seconds')),
                  const DropdownMenuItem(value: 40, child: Text('40 seconds')),
                  const DropdownMenuItem(value: 60, child: Text('1 minute')),
                  const DropdownMenuItem(value: 90, child: Text('1.5 minutes')),
                  const DropdownMenuItem(value: 120, child: Text('2 minutes')),
                  const DropdownMenuItem(value: 180, child: Text('3 minutes')),
                  const DropdownMenuItem(value: 300, child: Text('5 minutes')),
                  const DropdownMenuItem(value: 600, child: Text('10 minutes')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 90.0), // Pulls button UP a bit
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFBB13A), Color(0xFFF4732F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _saveReminders,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding:
                  const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'SAVE REMINDERS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestAlarmButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            await _playAlarm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text(
            'TEST ALARM (40 SEC)',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _alarmStopTimer?.cancel();
    _audioPlayer.dispose();
    _alarmService.dispose();
    super.dispose();
  }
}