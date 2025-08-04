// This is a demo version with the audio test widget included
// You can integrate the test widget into your main reminder screen temporarily for testing

import 'package:flutter/material.dart';
import 'package:sabbath_app/services/audio_reminder_service.dart';
import 'package:sabbath_app/widgets/audio_test_widget.dart';

class ReminderScreenWithTest extends StatefulWidget {
  const ReminderScreenWithTest({super.key});

  @override
  State<ReminderScreenWithTest> createState() => _ReminderScreenWithTestState();
}

class _ReminderScreenWithTestState extends State<ReminderScreenWithTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sabbath Reminder - Test Mode'),
        backgroundColor: const Color(0xFFF4732F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Add the audio test widget
            const AudioTestWidget(),
            
            const SizedBox(height: 24),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 How to Test Audio Reminders',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Click "Test Audio (40s)" to simulate a Sabbath reminder\n'
                    '2. Audio will play for 40 seconds with looped sound\n'
                    '3. An ongoing notification will show with countdown\n'
                    '4. You can stop the audio anytime using the "Stop" button\n'
                    '5. Audio continues even if app is minimized',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Integration info
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ Integration Complete',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your main ReminderScreen now includes:\n'
                    '• 40-second audio playback for all Sabbath reminders\n'
                    '• Ongoing notification with countdown\n'
                    '• Stop button in UI when audio is playing\n'
                    '• Background audio support\n'
                    '• Crash recovery for interrupted playback',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Features explanation
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                border: Border.all(color: Colors.purple),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎵 Audio Features',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Exactly 40 seconds of audio playback\n'
                    '• Looped audio file (notification.mp3)\n'
                    '• Maximum volume for alarm-like behavior\n'
                    '• Works when app is minimized or in background\n'
                    '• Shows progress countdown in notification\n'
                    '• User can stop audio anytime\n'
                    '• Recovers playback after app restart',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}