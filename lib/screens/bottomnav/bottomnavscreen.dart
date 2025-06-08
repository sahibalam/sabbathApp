import 'package:flutter/material.dart';
import 'package:sabbath_app/screens/ideas/ideasscreen.dart';
import '../bible/biblescreen.dart';
import '../futuredate/futuredatescreen.dart';
import '../home/homescreen.dart';
import '../reminder/reminderscreen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int currentIndex = 0;
  List<Widget> pages = [
    HomeScreen(),
    FutureDateScreen(),
    BibleScreen(),
    ReminderScreen(),
    IdeaScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFFF4732F), // Your active color
        unselectedItemColor: Colors.grey, // Inactive color
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(color: Colors.grey),
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/home.png',
              width: 24,
              height: 24,
              color: currentIndex == 0 ? const Color(0xFFF4732F) : Colors.grey,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/calendar.png',
              width: 24,
              height: 24,
              color: currentIndex == 1 ? const Color(0xFFF4732F) : Colors.grey,
            ),
            label: 'Date',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/open-magazine.png',
              width: 24,
              height: 24,
              color: currentIndex == 2 ? const Color(0xFFF4732F) : Colors.grey,
            ),
            label: 'Bible',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/alarm.png',
              width: 24,
              height: 24,
              color: currentIndex == 3 ? const Color(0xFFF4732F) : Colors.grey,
            ),
            label: 'Reminder',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/idea.png',
              width: 24,
              height: 24,
              color: currentIndex == 4 ? const Color(0xFFF4732F) : Colors.grey,
            ),
            label: 'Idea',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}
