import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // Constants for easy maintenance
  static const _supportEmail = 'support@thesabbathapp.com';
  static const _suggestionEmail = 'suggestions@thesabbathapp.com';
  static const _supportSubject = 'Support Request for The Sabbath App';
  static const _suggestionSubject = 'Suggestion for The Sabbath App';
  static const _suggestionFriendSubject = 'You should try The Sabbath App';
  static const _emailBody = 'Hello Sabbath App team,\n\n';
  static const _gradientColors = [
    Color(0xFFF4732F),
    Color(0xFFFBB13A),
    Color(0xFFFBB13A),
    Color(0xFFF4732F),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: constraints.maxWidth > constraints.maxHeight
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Flexible(child: _buildButtonColumn())],
                        )
                      : _buildButtonColumn(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildButtonColumn() {
    final buttonLabels = [
      "Facebook",
      "Tell A Friend",
      "Support",
      "Suggestion",
      "The Sabbath App Website",
      "Bless Channel Website",
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttonLabels.map(_buildButton).toList(),
      ),
    );
  }

  Widget _buildButton(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () => _handleButtonPress(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Text(label),
      ),
    );
  }

  Future<void> _handleButtonPress(String label) async {
    switch (label) {
      case "Suggestion":
        await _launchEmail(
          recipient: _suggestionEmail,
          subject: _suggestionSubject,
        );
        break;
      case "Support":
        await _launchEmail(recipient: _supportEmail, subject: _supportSubject);
        break;
      case "Tell A Friend":
        await _launchEmail(recipient: '', subject: _suggestionFriendSubject);
        break;
      default:
        debugPrint('$label tapped!');
    }
  }

  Future<void> _launchEmail({
    required String recipient,
    required String subject,
  }) async {
    try {
      final uri = Uri(
        scheme: 'mailto',
        path: recipient,
        queryParameters: {'subject': subject, 'body': _emailBody},
      );

      if (await _launchUrlWithFallback(uri)) return;

      // Fallback to Gmail web interface
      final webUri = Uri.parse(
        'https://mail.google.com/mail/?view=cm&to=$recipient'
        '&su=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(_emailBody)}',
      );

      if (!await _launchUrlWithFallback(webUri)) {
        _showErrorSnackbar('No email app available');
      }
    } catch (e) {
      debugPrint('Email launch error: $e');
      _showErrorSnackbar('Failed to launch email');
    }
  }

  Future<bool> _launchUrlWithFallback(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('URL launch failed: $e');
      return false;
    }
  }

  void _showErrorSnackbar(String message) {
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
