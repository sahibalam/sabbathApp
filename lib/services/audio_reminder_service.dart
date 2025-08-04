import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioReminderService {
  static final AudioReminderService _instance = AudioReminderService._internal();
  factory AudioReminderService() => _instance;
  AudioReminderService._internal();

  static const int AUDIO_DURATION_SECONDS = 40;
  static const String CHANNEL_ID = 'sabbath_audio_reminders';
  static const String ONGOING_NOTIFICATION_ID = 'ongoing_audio_reminder';

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _audioTimer;
  Timer? _progressTimer;
  bool _isPlaying = false;
  int _remainingSeconds = 0;
  
  // Callback for UI updates
  Function(bool isPlaying, int remainingSeconds)? onAudioStateChanged;

  FlutterLocalNotificationsPlugin? _notificationPlugin;

  /// Initialize the audio service
  Future<void> initialize(FlutterLocalNotificationsPlugin notificationPlugin) async {
    _notificationPlugin = notificationPlugin;
    
    // Configure audio player
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(1.0);
    
    // Set up audio session for alarm-like behavior
    if (Platform.isIOS) {
      await _audioPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ),
      );
    } else if (Platform.isAndroid) {
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
          ),
        ),
      );
    }
  }

  /// Start playing the Sabbath reminder audio
  Future<void> startReminderAudio({
    required String title,
    required String message,
    String audioAsset = 'sounds/notification.mp3',
  }) async {
    if (_isPlaying) {
      debugPrint('Audio reminder already playing, stopping current playback');
      await stopReminderAudio();
    }

    try {
      debugPrint('Starting Sabbath audio reminder: $title');
      
      _isPlaying = true;
      _remainingSeconds = AUDIO_DURATION_SECONDS;
      
      // Show ongoing notification
      await _showOngoingNotification(title, message);
      
      // Start audio playback
      await _audioPlayer.play(AssetSource(audioAsset));
      
      // Start progress timer (updates every second)
      _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          _updateOngoingNotification(title, _remainingSeconds);
          onAudioStateChanged?.call(_isPlaying, _remainingSeconds);
        }
      });
      
      // Start main timer to stop after specified duration
      _audioTimer = Timer(const Duration(seconds: AUDIO_DURATION_SECONDS), () {
        stopReminderAudio();
      });
      
      // Save state for crash recovery
      await _savePlaybackState(true, title, message);
      
      // Notify UI
      onAudioStateChanged?.call(_isPlaying, _remainingSeconds);
      
    } catch (e) {
      debugPrint('Error starting audio reminder: $e');
      _isPlaying = false;
      onAudioStateChanged?.call(_isPlaying, 0);
    }
  }

  /// Stop the reminder audio
  Future<void> stopReminderAudio() async {
    debugPrint('Stopping Sabbath audio reminder');
    
    _isPlaying = false;
    _remainingSeconds = 0;
    
    // Stop timers
    _audioTimer?.cancel();
    _progressTimer?.cancel();
    _audioTimer = null;
    _progressTimer = null;
    
    // Stop audio
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
    
    // Clear notifications
    await _clearOngoingNotification();
    
    // Clear saved state
    await _savePlaybackState(false, '', '');
    
    // Notify UI
    onAudioStateChanged?.call(_isPlaying, _remainingSeconds);
  }

  /// Show ongoing notification while audio plays
  Future<void> _showOngoingNotification(String title, String message) async {
    if (_notificationPlugin == null) return;

    const androidDetails = AndroidNotificationDetails(
      CHANNEL_ID,
      'Sabbath Audio Reminders',
      channelDescription: 'Ongoing audio reminders for Sabbath times',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      icon: '@mipmap/ic_stat',
      color: Color(0xFFF4732F),
      actions: [
        AndroidNotificationAction(
          'stop_audio',
          'Stop',
          cancelNotification: false,
          showsUserInterface: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false, // We're handling sound ourselves
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _notificationPlugin!.show(
      999, // Fixed ID for ongoing notification
      title,
      '$message (${_remainingSeconds}s remaining)',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'stop_audio',
    );
  }

  /// Update ongoing notification with remaining time
  void _updateOngoingNotification(String title, int remainingSeconds) {
    if (_notificationPlugin == null || !_isPlaying) return;

    const androidDetails = AndroidNotificationDetails(
      CHANNEL_ID,
      'Sabbath Audio Reminders',
      channelDescription: 'Ongoing audio reminders for Sabbath times',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      icon: '@mipmap/ic_stat',
      color: Color(0xFFF4732F),
      actions: [
        AndroidNotificationAction(
          'stop_audio',
          'Stop',
          cancelNotification: false,
          showsUserInterface: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false, // Don't show alert for updates
      presentBadge: true,
      presentSound: false,
    );

    _notificationPlugin!.show(
      999,
      title,
      'Playing reminder audio (${remainingSeconds}s remaining)',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'stop_audio',
    );
  }

  /// Clear the ongoing notification
  Future<void> _clearOngoingNotification() async {
    if (_notificationPlugin == null) return;
    await _notificationPlugin!.cancel(999);
  }

  /// Save playback state for crash recovery
  Future<void> _savePlaybackState(bool isPlaying, String title, String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_reminder_playing', isPlaying);
    await prefs.setString('audio_reminder_title', title);
    await prefs.setString('audio_reminder_message', message);
    await prefs.setInt('audio_reminder_start_time', 
        isPlaying ? DateTime.now().millisecondsSinceEpoch : 0);
  }

  /// Recover playback state after app restart
  Future<void> recoverPlaybackState() async {
    final prefs = await SharedPreferences.getInstance();
    final wasPlaying = prefs.getBool('audio_reminder_playing') ?? false;
    
    if (wasPlaying) {
      final startTime = prefs.getInt('audio_reminder_start_time') ?? 0;
      final title = prefs.getString('audio_reminder_title') ?? 'Sabbath Reminder';
      final message = prefs.getString('audio_reminder_message') ?? 'Audio reminder playing';
      
      if (startTime > 0) {
        final elapsed = (DateTime.now().millisecondsSinceEpoch - startTime) ~/ 1000;
        
        if (elapsed < AUDIO_DURATION_SECONDS) {
          // Resume playback
          _remainingSeconds = AUDIO_DURATION_SECONDS - elapsed;
          await startReminderAudio(title: title, message: message);
        } else {
          // Clear stale state
          await _savePlaybackState(false, '', '');
        }
      }
    }
  }

  /// Handle notification actions
  Future<void> handleNotificationAction(String? payload) async {
    if (payload == 'stop_audio' || payload == 'sabbath_reminder_audio') {
      await stopReminderAudio();
    }
  }

  /// Getters for current state
  bool get isPlaying => _isPlaying;
  int get remainingSeconds => _remainingSeconds;

  /// Dispose resources
  void dispose() {
    _audioTimer?.cancel();
    _progressTimer?.cancel();
    _audioPlayer.dispose();
  }
}