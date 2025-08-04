# Audio Duration Implementation Guide

## Overview
Your Sabbath reminder app now supports **configurable audio duration** that works alongside your existing local notifications. The solution extends your current alarm service to play audio for the full duration you specify, not just the 2-second limitation of local notifications.

## How It Works

### 🔧 Technical Implementation
1. **Local notifications remain unchanged** - They still fire at the correct times with the short system sound
2. **Extended audio playback** - When a notification fires, it also triggers the `AlarmService` to play your audio file for the full specified duration
3. **Configurable duration** - Users can now select how long the audio should play (10 seconds to 10 minutes)

### 🎵 Audio Flow
```
Scheduled Time Arrives
       ↓
Local Notification Fires (2 sec system sound)
       ↓
AlarmService Triggers (Full duration audio)
       ↓
Audio plays for configured duration with loop
```

## New Features Added

### 📱 Audio Duration Selector
- Located above the reminder time options
- Dropdown with preset durations: 10s, 20s, 30s, 40s, 1min, 1.5min, 2min, 3min, 5min, 10min
- Setting is saved automatically and persists between app sessions

### 🔊 Enhanced Audio Capabilities
- **Loop mode**: Audio repeats until the duration expires
- **Maximum volume**: Ensures audibility for important reminders
- **Background playback**: Continues even when app is backgrounded
- **Foreground notification**: Shows persistent notification during playback (Android)

## Setup Instructions

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Add Your Audio File
Place your notification audio file at:
```
assets/sounds/notification.mp3
```

### 3. Audio File Requirements
- **Format**: MP3, WAV, or M4A
- **Duration**: Can be any length (will loop if shorter than selected duration)
- **Quality**: 128kbps or higher recommended
- **Size**: Keep under 2MB for best performance

## Usage

### For Users
1. Open the Reminder screen
2. Select desired **Audio Duration** from dropdown
3. Choose your reminder times (10min, 20min, etc.)
4. Tap **SAVE REMINDERS**

### For Developers
The audio duration is controlled by:
```dart
int _alarmDurationSeconds = 40; // Default value
```

Saved in SharedPreferences as:
```dart
'alarm_duration_seconds'
```

## Key Files Modified

### `lib/screens/reminder_screen.dart`
- Added `_alarmDurationSeconds` variable
- Added `_buildAudioDurationSelector()` widget
- Added `_loadAlarmDuration()` and `_saveAlarmDuration()` methods
- Updated all alarm scheduling to use configurable duration

### `pubspec.yaml`
- Added `audioplayers: ^6.1.0` dependency
- Added `assets/sounds/` to asset bundle

### `lib/services/alarm_service.dart`
- Already exists and handles the full-duration audio playback
- Supports loop mode, volume control, and foreground notifications

## Testing

### Test the Audio Duration
1. Set a short duration (10-20 seconds) for testing
2. Use the "Test Alarm" button (if available)
3. Verify audio plays for the full selected duration
4. Test different duration settings

### Test Notifications
1. Set a reminder for 1-2 minutes in the future
2. Put app in background
3. When notification fires, verify both:
   - System notification appears
   - Full-duration audio starts playing

## Troubleshooting

### Audio Not Playing
- Ensure `notification.mp3` exists in `assets/sounds/`
- Check device volume settings
- Verify permissions are granted

### Audio Stops Early
- Check if device has aggressive battery optimization
- Ensure app has background audio permissions
- Test with shorter durations first

### No System Notification
- Verify notification permissions
- Check if Do Not Disturb is enabled
- Test with exact alarm permissions (Android 12+)

## Benefits

✅ **Keeps existing notification system intact**
✅ **Extends audio duration beyond system limitations** 
✅ **User-configurable duration**
✅ **Persistent audio playback**
✅ **Works in background**
✅ **Cross-platform compatible**

This implementation gives you the best of both worlds: reliable system notifications AND extended audio playback for your Sabbath reminders!