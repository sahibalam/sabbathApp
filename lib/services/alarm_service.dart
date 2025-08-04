import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _alarmTimer;
  bool _isPlaying = false;
  late FlutterLocalNotificationsPlugin _notificationPlugin;
  final List<Timer> _scheduledAlarms = []; // Track scheduled alarms

  // Initialize the alarm service
  Future<void> initialize(FlutterLocalNotificationsPlugin notificationPlugin) async {
    _notificationPlugin = notificationPlugin;
    
    // Configure audio player for alarms
    await _audioPlayer.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          contentType: AndroidContentType.sonification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );
  }

  // Start playing alarm for specified duration
  Future<void> startAlarm({
    String title = "Sabbath Reminder",
    String body = "Sabbath time!",
    int durationSeconds = 40,
  }) async {
    if (_isPlaying) {
      await stopAlarm();
    }

    _isPlaying = true;

    try {
      // Show foreground notification on Android
      if (Platform.isAndroid) {
        await _showForegroundNotification(title, body);
      }

      // Set maximum volume and loop mode
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      // Start playing the alarm sound
      await _audioPlayer.play(
        AssetSource('sounds/notification.mp3'),
        mode: PlayerMode.mediaPlayer,
      );

      // Set timer to stop after specified duration
      _alarmTimer = Timer(Duration(seconds: durationSeconds), () async {
        await stopAlarm();
      });

      debugPrint('Alarm started for $durationSeconds seconds');
    } catch (e) {
      debugPrint('Error starting alarm: $e');
      _isPlaying = false;
    }
  }

  // Stop the alarm
  Future<void> stopAlarm() async {
    if (!_isPlaying) return;

    _isPlaying = false;
    _alarmTimer?.cancel();
    _alarmTimer = null;

    try {
      await _audioPlayer.stop();
      
      // Cancel foreground notification
      if (Platform.isAndroid) {
        await _notificationPlugin.cancel(999); // Foreground service notification ID
      }

      debugPrint('Alarm stopped');
    } catch (e) {
      debugPrint('Error stopping alarm: $e');
    }
  }

  // Show persistent notification for Android foreground service
  Future<void> _showForegroundNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'alarm_foreground_channel',
      'Alarm Notifications',
      channelDescription: 'Persistent alarm notifications',
      icon: '@mipmap/ic_stat',
      color: Color(0xFFF4732F),
      importance: Importance.max,
      priority: Priority.high,
      playSound: false, // We handle sound separately
      enableVibration: true,
      ongoing: true, // Makes it persistent
      autoCancel: false,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      actions: [
        AndroidNotificationAction(
          'stop_alarm',
          'Stop Alarm',
          cancelNotification: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false, // We handle sound separately
      interruptionLevel: InterruptionLevel.critical,
    );

    await _notificationPlugin.show(
      999, // Fixed ID for foreground service
      title,
      '$body - Tap to stop alarm',
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: 'stop_alarm',
    );
  }

  // Schedule an alarm to start at a specific time
  void scheduleAlarm({
    required DateTime scheduledTime,
    String title = "Sabbath Reminder",
    String body = "Sabbath time!",
    int durationSeconds = 40,
  }) {
    final now = DateTime.now();
    final delay = scheduledTime.difference(now);
    
    if (delay.isNegative) {
      debugPrint('Scheduled time is in the past, not scheduling alarm');
      return;
    }

    final timer = Timer(delay, () async {
      debugPrint('⏰ Scheduled alarm triggered at ${DateTime.now()}');
      await startAlarm(
        title: title,
        body: body,
        durationSeconds: durationSeconds,
      );
    });

    _scheduledAlarms.add(timer);
    debugPrint('🔔 Alarm scheduled for ${scheduledTime.toLocal()} (in ${delay.inMinutes} minutes)');
  }

  // Cancel all scheduled alarms
  void cancelAllScheduledAlarms() {
    for (final timer in _scheduledAlarms) {
      timer.cancel();
    }
    _scheduledAlarms.clear();
    debugPrint('❌ All scheduled alarms cancelled');
  }

  // Check if alarm is currently playing
  bool get isPlaying => _isPlaying;

  // Dispose resources
  void dispose() {
    _alarmTimer?.cancel();
    cancelAllScheduledAlarms();
    _audioPlayer.dispose();
  }
}