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

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAlarm = false;
  Timer? _alarmTimer;
  final Map<String, Timer> _scheduledAudioTimers = {};

// 🔊 BULLETPROOF AUDIO SOLUTION - Independent from notifications
Future<void> _playAlarmIndependently() async {
  if (_isPlayingAlarm) return;

  setState(() => _isPlayingAlarm = true);
  
  try {
    // Stop any existing playback
    await _audioPlayer.stop();
    _alarmTimer?.cancel();

    // Configure audio session for maximum compatibility
    await _audioPlayer.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.duckOthers,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
        ),
      ),
    );

    // Set maximum volume and loop mode
    await _audioPlayer.setVolume(1.0);
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);

    // Start playback
    await _audioPlayer.play(
      AssetSource('sounds/notification.mp3'),
      mode: PlayerMode.mediaPlayer,
    );

    debugPrint('🔊 Audio alarm started independently');

    // Show in-app dialog if app is active
    if (mounted) {
      _showAlarmDialog('Sabbath Reminder');
    }

    // Auto-stop after 30 seconds to prevent infinite loop
    _alarmTimer = Timer(const Duration(seconds: 30), () {
      _stopAlarm();
    });

  } catch (e) {
    debugPrint('❌ Audio alarm error: $e');
    setState(() => _isPlayingAlarm = false);
  }
}

Future<void> _stopAlarm() async {
  if (!_isPlayingAlarm) return;
  
  try {
    await _audioPlayer.stop();
    _alarmTimer?.cancel();
    setState(() => _isPlayingAlarm = false);
    
    // Close any open dialogs
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    
    debugPrint('🔇 Audio alarm stopped');
  } catch (e) {
    debugPrint('Error stopping alarm: $e');
  }
}

// Backward compatibility
Future<void> _playAlarm() async {
  await _playAlarmIndependently();
}

  @override
  void initState() {
    super.initState();
    notificationPlugin = FlutterLocalNotificationsPlugin();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initNotification();
      await _loadLastLocation();
      await _updateTimes();
      await _loadSavedReminders();
    });
  }

  Future<void> _initNotification() async {
    try {
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

      // 🔇 SILENT NOTIFICATION SETUP - No built-in sounds
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_stat');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: false, // ❌ DISABLE built-in sound
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(android: androidSettings, iOS: iosSettings);

      await notificationPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) async {
          debugPrint('📱 Notification tapped: ${details.payload}');
          if (details.payload == 'sabbath_alarm') {
            // Play our custom audio when notification is tapped
            await _playAlarmIndependently();
          }
        },
      );

      debugPrint('✅ Silent notification service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(appTitle: 'Sabbath App', appVersion: 'v2.0.4'),
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
            Expanded(child: _buildReminderOptions()),
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
  // Clear all existing notifications and timers
  await notificationPlugin.cancelAll();
  _cancelAllAudioTimers();

  final now = tz.TZDateTime.now(tz.local);
  final nextStart = _calculateNextSabbathStart(now);
  final nextEnd = _calculateNextSabbathEnd(now);

  debugPrint('\n=== 🕯️ SABBATH REMINDER SCHEDULING ===');
  debugPrint('⏰ Current Time: ${now.toLocal()}');
  debugPrint('🕯️ Next Sabbath Start: ${nextStart.toLocal()}');
  debugPrint('🔚 Next Sabbath End: ${nextEnd.toLocal()}');

  // Validate times are in the future
  if (nextStart.isBefore(now) || nextEnd.isBefore(now)) {
    debugPrint('⚠️ Sabbath times are in the past! Not scheduling reminders.');
    return;
  }

  // Schedule reminders for each selected time
  for (final entry in reminderTimes.entries.where((e) => e.value)) {
    final minutes = entry.key;
    final duration = Duration(minutes: minutes);

    // 🔇 SILENT notification + 🔊 INDEPENDENT audio for Sabbath START
    final startReminderTime = nextStart.subtract(duration);
    if (startReminderTime.isAfter(now)) {
      await _scheduleNotificationAndAudio(
        id: 'start_$minutes'.hashCode,
        title: 'Sabbath Starts Soon!',
        body: 'Sabbath begins in $minutes minutes',
        scheduledTime: startReminderTime,
      );
    }

    // 🔇 SILENT notification + 🔊 INDEPENDENT audio for Sabbath END
    final endReminderTime = nextEnd.subtract(duration);
    if (endReminderTime.isAfter(now)) {
      await _scheduleNotificationAndAudio(
        id: 'end_$minutes'.hashCode,
        title: 'Sabbath Ends Soon!',
        body: 'Sabbath ends in $minutes minutes',
        scheduledTime: endReminderTime,
      );
    }
  }

  // Schedule exact start/end notifications
  if (nextStart.isAfter(now)) {
    await _scheduleNotificationAndAudio(
      id: 'exact_start'.hashCode,
      title: 'Sabbath Has Started!',
      body: 'Shabbat Shalom!',
      scheduledTime: nextStart,
    );
  }

  if (nextEnd.isAfter(now)) {
    await _scheduleNotificationAndAudio(
      id: 'exact_end'.hashCode,
      title: 'Sabbath Has Ended',
      body: 'Have a blessed week!',
      scheduledTime: nextEnd,
    );
  }

  debugPrint('✅ All reminders scheduled with independent audio');
}

// 🎯 CORE SOLUTION: Schedule silent notification + independent audio
Future<void> _scheduleNotificationAndAudio({
  required int id,
  required String title,
  required String body,
  required tz.TZDateTime scheduledTime,
}) async {
  try {
    // 1️⃣ Schedule SILENT notification
    await notificationPlugin.cancel(id);
    await notificationPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'sabbath_silent_channel',
          'Silent Sabbath Reminders',
          channelDescription: 'Silent sabbath reminders with custom audio',
          icon: '@mipmap/ic_stat',
          color: const Color(0xFFF4732F),
          importance: Importance.max,
          priority: Priority.high,
          playSound: false, // ❌ NO built-in sound
          enableVibration: true,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false, // ❌ NO built-in sound
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'sabbath_alarm',
      matchDateTimeComponents: null,
    );

    // 2️⃣ Schedule INDEPENDENT audio at the same time
    _scheduleIndependentAudio(scheduledTime, title, id.toString());

    debugPrint('✅ Scheduled: $title at ${scheduledTime.toLocal()}');
  } catch (e) {
    debugPrint('❌ Error scheduling: $e');
  }
}

// 🔊 Schedule audio independently using Timer
void _scheduleIndependentAudio(tz.TZDateTime scheduledTime, String title, String timerId) {
  final now = tz.TZDateTime.now(tz.local);
  final delay = scheduledTime.difference(now);
  
  if (delay.isNegative) {
    debugPrint('⚠️ Cannot schedule audio in the past');
    return;
  }

  debugPrint('🔊 Audio scheduled for: ${scheduledTime.toLocal()} (in ${delay.inMinutes} minutes)');
  
  // Create timer to trigger audio at exact time
  final timer = Timer(delay, () async {
    debugPrint('🚨 AUDIO TRIGGER: $title');
    await _playAlarmIndependently();
  });
  
  // Store timer for cleanup
  _scheduledAudioTimers[timerId] = timer;
}

void _cancelAllAudioTimers() {
  for (final timer in _scheduledAudioTimers.values) {
    timer.cancel();
  }
  _scheduledAudioTimers.clear();
  debugPrint('🔇 All audio timers cancelled');
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
}

// Show in-app alarm dialog when audio plays
void _showAlarmDialog(String title) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.access_time, color: Color(0xFFF4732F), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          'Tap "Stop Alarm" to silence the notification sound.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _stopAlarm();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBB13A), Color(0xFFF4732F)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Stop Alarm',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    },
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

  @override
  void dispose() {
    _alarmTimer?.cancel();
    _cancelAllAudioTimers();
    _audioPlayer.dispose();
    super.dispose();
  }
}