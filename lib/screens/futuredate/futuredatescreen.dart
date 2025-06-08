import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:sabbath_app/utility/appdrawer.dart';
import '../../spa/suncal.dart';
import '../../utility/location_helper.dart';

class FutureDateScreen extends StatefulWidget {
  const FutureDateScreen({super.key});

  @override
  State<FutureDateScreen> createState() => _FutureDateScreenState();
}

class _FutureDateScreenState extends State<FutureDateScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String latitude = "";
  String longitude = "";
  late DateTime selectedDate;
  String sunriseTime = "--:--";
  String sunsetTime = "--:--";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    selectedDate = DateTime.now();
    fetchLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchLocation();
    }
  }

  void fetchLocation() async {
    Position? position = await LocationHelper.getCurrentLocation(context);
    if (position != null) {
      setState(() {
        latitude = position.latitude.toString();
        longitude = position.longitude.toString();
        _calculateSunTimes(selectedDate, position.latitude, position.longitude);
      });
    }
  }

  void _calculateSunTimes(DateTime date, double lat, double lng) {
    final sunrise = SunCalculator.calculateSunrise(
      date,
      lat,
      lng,
      Duration.zero,
    );
    final sunset = SunCalculator.calculateSunset(date, lat, lng, Duration.zero);

    final localSunrise = sunrise.toLocal();
    final localSunset = sunset.toLocal();

    setState(() {
      sunriseTime = DateFormat('hh:mm a').format(localSunrise);
      sunsetTime = DateFormat('hh:mm a').format(localSunset);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        if (latitude.isNotEmpty && longitude.isNotEmpty) {
          _calculateSunTimes(
            selectedDate,
            double.parse(latitude),
            double.parse(longitude),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Add this key
      drawer: AppDrawer(appTitle: 'Sabbath App', appVersion: 'v1.0.0'),
      body: Builder(
        builder: (context) {
          if (MediaQuery.of(context).orientation == Orientation.portrait) {
            return portraitWidget(context);
          } else {
            return landscapeWidget(context);
          }
        },
      ),
    );
  }

  Widget portraitWidget(BuildContext context) {
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Search location...",
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: Colors.grey[700],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dateOverlay(DateFormat('d').format(selectedDate)),
                      _dateOverlay(DateFormat('MMM').format(selectedDate)),
                      _dateOverlay(DateFormat('y').format(selectedDate)),
                      _iconOverlay(context),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: 280,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade400,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wb_sunny,
                              color: Colors.white,
                              size: 80,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              sunriseTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 180, color: Colors.white),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.nights_stay,
                              color: Colors.white,
                              size: 80,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              sunsetTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget landscapeWidget(BuildContext context) {
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: "Search location...",
                          prefixIcon: const Icon(
                            Icons.location_on,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          _dateOverlay(DateFormat('d').format(selectedDate)),
                          _dateOverlay(DateFormat('MMM').format(selectedDate)),
                          _dateOverlay(DateFormat('y').format(selectedDate)),
                          _iconOverlay(context),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  flex: 2,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade400,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.wb_sunny,
                                color: Colors.white,
                                size: 80,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                sunriseTime,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 180, color: Colors.white),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.nights_stay,
                                color: Colors.white,
                                size: 80,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                sunsetTime,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateOverlay(String text) {
    return Container(
      width: 52,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withOpacity(0.8), // Slightly transparent
        borderRadius: BorderRadius.circular(4), // Added subtle rounding
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _iconOverlay(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        width: 52,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 6.0),
        decoration: BoxDecoration(
          color: Color(0xFFF4732F), // Matched the gradient start color
          borderRadius: BorderRadius.circular(4), // Consistent with date boxes
        ),
        child: const Icon(
          Icons.calendar_today,
          color: Colors.white,
          size: 24, // Slightly smaller for better proportion
        ),
      ),
    );
  }
}
