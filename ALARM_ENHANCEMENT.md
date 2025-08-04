# Sabbath App - Enhanced 40-Second Alarm Feature

## Overview
The Sabbath app now includes an enhanced alarm system that plays audio notifications for **40 seconds** instead of the default 2-3 seconds from local notifications.

## Key Features

### 🔊 Extended Audio Playback
- **Duration**: 40 seconds (configurable)
- **Volume**: Maximum volume with speaker output
- **Loop Mode**: Continuous playback until timer expires
- **Cross-Platform**: Works on both iOS and Android

### 🛡️ Reliable Background Execution
- **Foreground Service**: Android uses foreground service for uninterrupted playback
- **Wake Lock**: Prevents device sleep during alarm
- **Battery Optimization**: Bypasses battery optimization restrictions

### 🎛️ User Controls
- **Test Button**: Purple "TEST ALARM (40 SEC)" button for testing
- **Stop Button**: Red floating action button appears during alarm playback
- **Notification Actions**: Tap notification to stop alarm

## Technical Implementation

### AlarmService
- **Singleton Pattern**: Single instance manages all alarm operations
- **Timer-Based**: Automatically stops after specified duration
- **Resource Management**: Proper cleanup and disposal

### Notification Integration
- **Payload Handling**: 
  - `'alarm'` → Starts 40-second alarm
  - `'stop_alarm'` → Stops current alarm
- **Foreground Notifications**: Persistent notification during playback

### Permissions (Android)
```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
```

## Usage

### Setting Up Reminders
1. Select desired reminder times (10, 20, 30, 60 minutes, or 1+ hours)
2. Tap "SAVE REMINDERS" to schedule notifications
3. When Sabbath time arrives, notifications trigger 40-second alarms

### Testing the Alarm
1. Tap the purple "TEST ALARM (40 SEC)" button
2. Audio will play for 40 seconds
3. Use the red "Stop Alarm" floating button to stop early

### During Actual Reminders
1. Scheduled notifications automatically trigger 40-second alarms
2. Tap the notification or use the stop button to silence
3. Alarm automatically stops after 40 seconds

## Benefits Over Local Notifications

| Feature | Local Notification | Enhanced Alarm |
|---------|-------------------|----------------|
| Duration | ~2-3 seconds | 40 seconds |
| Volume Control | System limited | Maximum volume |
| Background Play | Limited | Foreground service |
| User Control | None | Stop button |
| Reliability | OS dependent | Service guaranteed |

## Troubleshooting

### Android Issues
- **No Sound**: Check app permissions and battery optimization
- **Short Duration**: Ensure foreground service permissions granted
- **Background Limitations**: Add app to battery whitelist

### iOS Issues
- **Silent Mode**: Alarm respects silent mode settings
- **Background App Refresh**: Enable for reliable operation

## Future Enhancements
- Configurable alarm duration
- Multiple alarm tones
- Gradual volume increase
- Snooze functionality
- Custom alarm schedules