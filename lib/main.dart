import 'package:flutter/material.dart';
import 'package:sabbath_app/screens/bottomnav/bottomnavscreen.dart';
import 'package:sabbath_app/screens/privacypolicy/privacypolicy.dart';
import 'package:sabbath_app/utility/noti_service.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  // if (await Permission.location.isDenied) {
  //   await Permission.location.request();
  // }
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotiService().initNotification();

  await requestPermissions();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Sabbath App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF4732F), // Using your orange color
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const BottomNavScreen(),
      routes: {
        '/privacy': (context) => const PrivacyPolicyScreen(),
        // Add other routes here as needed
      },
    );
  }
}
