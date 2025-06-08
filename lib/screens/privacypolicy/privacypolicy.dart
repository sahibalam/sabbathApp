import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Privacy Policy'),
      //   backgroundColor: const Color(0xFFF4732F),
      // ),
      body: Builder(
        builder: (context) {
          if (MediaQuery.of(context).orientation == Orientation.portrait) {
            return contentWidget(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            );
          } else {
            return contentWidget(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            );
          }
        },
      ),
    );
  }

  Widget contentWidget({required EdgeInsets padding}) {
    return Container(
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
          padding: padding,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Last Updated: 25 May 2025',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 24),

                sectionTitle('1. Introduction'),
                bulletPoint(
                  'This privacy policy explains how The Sabbath App handles your location data.',
                ),
                bulletPoint(
                  'The App is non-commercial, free to use, and does not store, share, or sell your personal information to any third parties.',
                ),
                const SizedBox(height: 16),

                sectionTitle('2. Data Collection and Use'),
                bulletPoint(
                  'The App only accesses your device\'s location (GPS) to provide core functionality (e.g., sunrise/sunset calculations).',
                ),
                bulletPoint(
                  'No storage: Your location is processed in real-time and never saved on our servers or your device.',
                ),
                bulletPoint(
                  'No sharing: We do not transmit, sell, or share your location with third parties.',
                ),
                bulletPoint(
                  'Offline operation: All calculations occur locally on your device.',
                ),
                const SizedBox(height: 16),

                sectionTitle('3. Permissions'),
                bulletPoint(
                  'The App requests location permissions (while using the app or always) only to:',
                ),
                bulletPoint(
                  '• Provide accurate location-based results.',
                  indent: 16,
                ),
                bulletPoint(
                  '• Function without requiring manual input of coordinates.',
                  indent: 16,
                ),
                bulletPoint(
                  'You can revoke these permissions anytime via your device settings.',
                ),
                const SizedBox(height: 16),

                sectionTitle('4. No Data Retention'),
                bulletPoint(
                  'Your location is deleted immediately after processing.',
                ),
                bulletPoint('No logs, backups, or databases are created.'),
                const SizedBox(height: 16),

                sectionTitle('5. Changes to This Policy'),
                bulletPoint(
                  'Updates will be posted here. Continued use of the App signifies acceptance of changes.',
                ),
                const SizedBox(height: 16),

                sectionTitle('6. Contact'),
                bulletPoint(
                  'For questions, contact: support@thesabbathapp.com',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget bulletPoint(String text, {double indent = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: 12.0 + indent, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (indent == 0)
            const Text(
              '• ',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
