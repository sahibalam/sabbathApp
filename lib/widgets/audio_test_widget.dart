import 'package:flutter/material.dart';
import 'package:sabbath_app/services/audio_reminder_service.dart';

class AudioTestWidget extends StatefulWidget {
  const AudioTestWidget({super.key});

  @override
  State<AudioTestWidget> createState() => _AudioTestWidgetState();
}

class _AudioTestWidgetState extends State<AudioTestWidget> {
  final AudioReminderService _audioService = AudioReminderService();
  bool _isPlaying = false;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    
    // Set up audio service callbacks
    _audioService.onAudioStateChanged = (isPlaying, remainingSeconds) {
      if (mounted) {
        setState(() {
          _isPlaying = isPlaying;
          _remainingSeconds = remainingSeconds;
        });
      }
    };
  }

  Future<void> _testAudioReminder() async {
    await _audioService.startReminderAudio(
      title: 'Test Sabbath Reminder',
      message: 'This is a test of the 40-second audio reminder',
    );
  }

  Future<void> _stopAudioReminder() async {
    await _audioService.stopReminderAudio();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🔊 Audio Test Panel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          if (_isPlaying) ...[
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.volume_up, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Audio Playing: ${_remainingSeconds}s remaining',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _stopAudioReminder,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Audio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ] else ...[
            const Text(
              'Test the 40-second audio reminder',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _testAudioReminder,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Test Audio (40s)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Note: Audio will play for 40 seconds with ongoing notification',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}