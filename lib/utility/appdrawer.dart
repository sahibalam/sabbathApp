import 'package:flutter/material.dart';
import 'package:sabbath_app/screens/home/addlocation.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatelessWidget {
  final String appTitle;
  final String appVersion;

  // Constants for easy maintenance
  static const _supportEmail = 'support@thesabbathapp.com';
  static const _suggestionEmail = 'suggestions@thesabbathapp.com';
  static const _supportSubject = 'Support Request for The Sabbath App';
  static const _suggestionSubject = 'Suggestion for The Sabbath App';
  static const _suggestionFriendSubject = 'You should try The Sabbath App';
  static const _emailBody = 'Hello Sabbath App team,\n\n';

  const AppDrawer({
    super.key,
    required this.appTitle,
    required this.appVersion,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
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
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 180,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF4732F).withOpacity(0.9),
                    const Color(0xFFFBB13A).withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    appTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        const Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appVersion,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Add this new drawer item for locations
            _buildDrawerItem(
              context: context,
              icon: Icons.location_on,
              title: 'My Locations',
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddLocationScreen(),
                  ),
                ).then((_) {
                  // Optional: Add any callback logic when returning from AddLocationScreen
                });
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.thumb_up,
              title: 'Facebook',
              onTap: () => _launchFacebook(context),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.share,
              title: 'Tell A Friend',
              onTap: () => _launchEmail(
                context,
                recipient: '',
                subject: _suggestionFriendSubject,
              ),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.help_outline,
              title: 'Support',
              onTap: () => _launchEmail(
                context,
                recipient: _supportEmail,
                subject: _supportSubject,
              ),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.lightbulb_outline,
              title: 'Suggestions',
              onTap: () => _launchEmail(
                context,
                recipient: _suggestionEmail,
                subject: _suggestionSubject,
              ),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.language,
              title: 'Website',
              onTap: () => _launchWebsite(context),
            ),
            const Divider(
              color: Colors.white30,
              height: 20,
              indent: 20,
              endIndent: 20,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () => Navigator.pushNamed(context, '/privacy'),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.copyright,
              title: 'Damian Cox',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 26),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1)),
          ],
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      minLeadingWidth: 20,
      hoverColor: Colors.white.withOpacity(0.1),
      splashColor: Colors.white.withOpacity(0.2),
    );
  }

  Future<void> _launchFacebook(BuildContext context) async {
    try {
      const url = 'https://facebook.com/thesabbathapp';
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        _showErrorSnackbar(context, 'Could not launch Facebook');
      }
    } catch (e) {
      debugPrint('Facebook launch error: $e');
      _showErrorSnackbar(context, 'Failed to launch Facebook');
    }
  }

  Future<void> _launchWebsite(BuildContext context) async {
    try {
      const url = 'https://thesabbathapp.com';
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        _showErrorSnackbar(context, 'Could not launch website');
      }
    } catch (e) {
      debugPrint('Website launch error: $e');
      _showErrorSnackbar(context, 'Failed to launch website');
    }
  }

  Future<void> _launchEmail(
    BuildContext context, {
    required String recipient,
    required String subject,
  }) async {
    try {
      Navigator.pop(context); // Close the drawer first

      final uri = Uri(
        scheme: 'mailto',
        path: recipient,
        queryParameters: {'subject': subject, 'body': _emailBody},
      );

      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;

      // Fallback to Gmail web interface
      final webUri = Uri.parse(
        'https://mail.google.com/mail/?view=cm&to=$recipient'
        '&su=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(_emailBody)}',
      );

      if (!await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
        _showErrorSnackbar(context, 'No email app available');
      }
    } catch (e) {
      debugPrint('Email launch error: $e');
      _showErrorSnackbar(context, 'Failed to launch email');
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
