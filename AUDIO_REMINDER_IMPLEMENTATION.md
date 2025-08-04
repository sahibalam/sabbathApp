# 40-Second Audio Reminder Implementation

## Overview

This implementation replaces the short notification sounds with a 40-second audio reminder that plays like an adhan when Sabbath reminders are triggered. The system combines local push notifications with extended audio playback to create a more prominent reminder experience.

## Key Components

### 1. AudioReminderService (`lib/services/audio_reminder_service.dart`)

A singleton service that manages long-duration audio playback:

- **Duration**: Exactly 40 seconds of audio playback
- **Audio Loop**: Continuously loops the notification sound for the entire duration
- **Volume**: Maximum volume for alarm-like behavior
- **Background Support**: Continues playing when app is minimized
- **State Recovery**: Recovers playback after app crashes or restarts

### 2. Enhanced ReminderScreen (`lib/screens/reminder/reminder_screen_new.dart`)

Your main reminder screen with integrated audio functionality:

- **Notification Handling**: When Sabbath reminders trigger, they start the 40-second audio
- **UI Controls**: Shows audio control widget with stop button when audio is playing
- **Visual Feedback**: Real-time countdown display showing remaining seconds

### 3. Audio Test Widget (`lib/widgets/audio_test_widget.dart`)

A debugging widget to test the audio functionality:

- **Manual Testing**: Button to trigger 40-second audio test
- **Status Display**: Shows playing status and remaining time
- **Stop Control**: Button to manually stop audio during testing

## How It Works

### 1. Normal Notification Flow
```
Sabbath Time Reached
↓
Local Push Notification Fires
↓
Notification Handler Triggered
↓
AudioReminderService.startReminderAudio() Called
↓
40-Second Audio Begins + Ongoing Notification Shown
↓
Audio Stops Automatically After 40 Seconds
```

### 2. Audio Features

- **Looped Playback**: Uses `ReleaseMode.loop` to repeat the sound file
- **Timer Management**: 40-second master timer + 1-second update timer
- **Ongoing Notification**: Shows countdown with stop action button
- **Cross-Platform**: Works on both iOS and Android
- **Background Audio**: Continues playing when app is in background

### 3. User Experience

- **Notification Appears**: Standard Sabbath reminder notification
- **Audio Begins**: 40 seconds of looped audio at maximum volume
- **Ongoing Feedback**: Persistent notification with countdown
- **User Control**: Can stop audio anytime via notification or app UI
- **Auto-Stop**: Audio stops automatically after 40 seconds

## Integration Changes Made

### In ReminderScreen:

1. **Import Added**: `import 'package:sabbath_app/services/audio_reminder_service.dart';`

2. **Service Instance**: 
   ```dart
   late AudioReminderService _audioService;
   ```

3. **Audio State Tracking**:
   ```dart
   bool _isAudioPlaying = false;
   int _audioRemainingSeconds = 0;
   ```

4. **Notification Handler Modified**:
   ```dart
   payload: 'sabbath_reminder_audio' // Triggers audio instead of short sound
   ```

5. **UI Enhancement**:
   ```dart
   if (_isAudioPlaying) _buildAudioControl(), // Shows stop button
   ```

### Key Methods:

- `AudioReminderService.startReminderAudio()`: Starts 40-second playback
- `AudioReminderService.stopReminderAudio()`: Stops playback immediately
- `AudioReminderService.recoverPlaybackState()`: Recovers after app restart

## Testing

### Manual Testing:
1. Use the `AudioTestWidget` to test 40-second audio
2. Verify audio continues when app is minimized
3. Test stop functionality
4. Verify notification countdown

### Integration Testing:
1. Set a reminder for a few minutes from now
2. Wait for notification to trigger
3. Verify 40-second audio plays automatically
4. Test stop button functionality

## File Structure
```
lib/
├── services/
│   └── audio_reminder_service.dart          # Main audio service
├── screens/reminder/
│   ├── reminder_screen_new.dart             # Your updated reminder screen
│   └── reminder_screen_with_test.dart       # Demo version with test widget
└── widgets/
    └── audio_test_widget.dart               # Test widget for debugging
```

## Audio File Requirements

- **File Location**: `assets/sounds/notification.mp3`
- **Format**: MP3 format recommended
- **Duration**: Any duration (will be looped for 40 seconds)
- **Quality**: Clear, loud audio suitable for alarms

## Platform-Specific Notes

### Android:
- Uses `AndroidUsageType.alarm` for alarm-like behavior
- Requests battery optimization permissions
- Shows ongoing notification with stop action

### iOS:
- Uses `AVAudioSessionCategory.playback`
- Configured for speaker output by default
- Time-sensitive notification interruption level

## Customization Options

### Change Duration:
```dart
// In AudioReminderService
static const int AUDIO_DURATION_SECONDS = 60; // Change to 60 seconds
```

### Change Audio File:
```dart
await _audioService.startReminderAudio(
  title: title,
  message: message,
  audioAsset: 'sounds/adhan.mp3', // Use different audio file
);
```

### Modify Notification:
Customize the ongoing notification appearance in `_showOngoingNotification()` method.

## Troubleshooting

### Audio Not Playing:
1. Verify audio file exists in `assets/sounds/`
2. Check device volume settings
3. Ensure notification permissions are granted
4. Test with `AudioTestWidget` first

### Audio Stops Early:
1. Check for battery optimization settings
2. Verify app has background audio permissions
3. Ensure device isn't in power saving mode

### Notification Issues:
1. Grant notification permissions
2. Allow background activity for the app
3. Disable battery optimization for the app

## Performance Considerations

- **Memory**: Service uses minimal memory with singleton pattern
- **Battery**: 40-second audio has minimal battery impact
- **CPU**: Timer updates every second during playback only
- **Storage**: Audio file cached in app assets

This implementation provides a robust, user-friendly way to play extended audio reminders for Sabbath notifications while maintaining good performance and cross-platform compatibility.