import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabbath_app/screens/home/addlocation.dart';
import 'package:sabbath_app/utility/appdrawer.dart';
import 'package:sabbath_app/spa/suncal.dart';
import 'package:sabbath_app/utility/location_helper.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int currentPageIndex = 0;
  late PageController _pageController;
  String latitude = "";
  String longitude = "";
  late String day;
  late String month;
  late String year;
  String sunriseTime = "--:--";
  String sunsetTime = "--:--";

  Duration sabbathBeginDuration = Duration.zero;
  Duration sabbathEndDuration = Duration.zero;
  bool _sabbathHasBegun = false;
  bool _sabbathHasEnded = false;

  Timer? _timer;

  String city = 'Loading...';
  String state = '';
  String country = '';
  Duration utcOffset = Duration.zero;

  List<Map<String, dynamic>> allLocations = [];

  // ADDED: Validate page index
  void _validatePageIndex() {
    if (currentPageIndex >= allLocations.length && allLocations.isNotEmpty) {
      currentPageIndex = allLocations.length - 1;
    } else if (allLocations.isEmpty) {
      currentPageIndex = 0;
    }
  }

  // ADDED: Safe state update with index validation
  void _safeSetState(Function() fn) {
    setState(() {
      fn();
      _validatePageIndex();
    });
  }

  Future<void> _cacheLocationData(
    String city,
    String state,
    String country,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_city', city);
    await prefs.setString('cached_state', state);
    await prefs.setString('cached_country', country);
  }

  Future<void> _loadCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      city = prefs.getString('cached_city') ?? 'Unknown Location';
      state = prefs.getString('cached_state') ?? '';
      country = prefs.getString('cached_country') ?? '';
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    tz.initializeTimeZones();
    _pageController = PageController();
    final now = DateTime.now();
    day = DateFormat('d').format(now);
    month = DateFormat('MMMM').format(now);
    year = DateFormat('y').format(now);
    _startTimer();
    _updateTimes();
    _loadSavedLocations();
  }

  Duration _getLocationOffset(Map<String, dynamic> location) {
    try {
      if (location['isCurrent'] == true) {
        return utcOffset;
      }

      final timezone = location['timezone'];
      if (timezone == null || timezone.isEmpty) return Duration.zero;

      final locationObj = tz.getLocation(timezone);
      final now = tz.TZDateTime.now(locationObj);
      return now.timeZoneOffset;
    } catch (e) {
      debugPrint("Error getting timezone offset: $e");
      return Duration.zero;
    }
  }

  Future<void> _loadSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? locationsJson = prefs.getString('selected_locations');

    List<Map<String, dynamic>> savedLocations = [];
    if (locationsJson != null) {
      savedLocations = List<Map<String, dynamic>>.from(
        json.decode(locationsJson),
      );
    }

    // CHANGED: Use safeSetState
    _safeSetState(() {
      allLocations = [
        {
          'city': city,
          'country': country,
          'latitude': latitude,
          'longitude': longitude,
          'timezone': 'current',
          'isCurrent': true,
        },
      ]..addAll(savedLocations);
    });
  }

  String _getSunsetTime(DateTime date, [Duration? offset]) {
    try {
      DateTime sunset = _getSunsetTimeForDate(date, offset ?? utcOffset);
      return "Sunset: ${DateFormat('hh:mm a').format(sunset)}";
    } catch (e) {
      return "Sunset: --:--";
    }
  }

  String _formatSabbathDate(DateTime date) {
    final day = DateFormat('d').format(date);
    final suffix = _getDaySuffix(int.parse(day));
    final month = DateFormat('MMMM').format(date);
    final weekday = DateFormat('EEEE').format(date);
    return '$weekday $day$suffix $month';
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdowns();
      if (currentPageIndex == 0) {
        _updateTimes();
      }
    });
  }

  DateTime _getCurrentSabbathStart(DateTime now, [Duration? offset]) {
    Duration effectiveOffset = offset ?? utcOffset;
    DateTime localNow = now.add(effectiveOffset);

    // Find the most recent Friday
    DateTime friday = localNow.subtract(
      Duration(days: (localNow.weekday - DateTime.friday + 7) % 7),
    );

    DateTime fridaySunset = _getSunsetTimeForDate(friday, effectiveOffset);

    // If we're BEFORE Friday sunset, use PREVIOUS Sabbath
    if (localNow.isBefore(fridaySunset)) {
      friday = friday.subtract(const Duration(days: 7));
      fridaySunset = _getSunsetTimeForDate(friday, effectiveOffset);
    }

    return fridaySunset; // Current Sabbath start
  }

  DateTime _getCurrentSabbathEnd(DateTime now, [Duration? offset]) {
    DateTime start = _getCurrentSabbathStart(now, offset);
    return start.add(const Duration(days: 1)); // Saturday sunset
  }

  DateTime _getNextSabbathStart(DateTime now, [Duration? offset]) {
    Duration effectiveOffset = offset ?? utcOffset;
    DateTime localNow = now.add(effectiveOffset);

    // Find next Friday
    DateTime nextFriday = localNow.add(
      Duration(days: (DateTime.friday - localNow.weekday + 7) % 7),
    );

    return _getSunsetTimeForDate(
      DateTime(nextFriday.year, nextFriday.month, nextFriday.day),
      effectiveOffset,
    );
  }

  DateTime _getNextSabbathEnd(DateTime now, [Duration? offset]) {
    DateTime nextSabbathStart = _getNextSabbathStart(now, offset ?? utcOffset);
    DateTime saturday = nextSabbathStart.add(const Duration(days: 1));
    return _getSunsetTimeForDate(saturday, offset ?? utcOffset);
  }

  DateTime _getSunsetTimeForDate(DateTime date, [Duration? offset]) {
    Duration effectiveOffset = offset ?? utcOffset;
    try {
      double lat = double.tryParse(latitude) ?? 0.0;
      double lng = double.tryParse(longitude) ?? 0.0;

      final sunsetUtc = SunCalculator.calculateSunset(
        date,
        lat,
        lng,
        effectiveOffset,
      );

      if (sunsetUtc.year == 0) {
        return DateTime(
          date.year,
          date.month,
          date.day,
          18,
          0,
        ).add(effectiveOffset);
      }

      // Return in local time
      return sunsetUtc;
    } catch (e) {
      debugPrint("Error calculating sunset: $e");
      return DateTime(
        date.year,
        date.month,
        date.day,
        18,
        0,
      ).add(effectiveOffset);
    }
  }

  void _updateCountdowns() {
    if (allLocations.isEmpty) return;

    final now = DateTime.now();
    Duration currentOffset = currentPageIndex == 0
        ? utcOffset
        : _getLocationOffset(allLocations[currentPageIndex]);

    final currentSabbathStart = _getCurrentSabbathStart(now, currentOffset);
    final currentSabbathEnd = _getCurrentSabbathEnd(now, currentOffset);
    final localNow = now.add(currentOffset);

    final isSabbath =
        localNow.isAfter(currentSabbathStart) &&
        localNow.isBefore(currentSabbathEnd);
    final sabbathEnded = localNow.isAfter(currentSabbathEnd);

    setState(() {
      _sabbathHasBegun = isSabbath;
      _sabbathHasEnded = sabbathEnded;

      if (isSabbath) {
        sabbathBeginDuration = Duration.zero;
        sabbathEndDuration = currentSabbathEnd.difference(localNow);
      } else if (sabbathEnded) {
        final nextStart = _getNextSabbathStart(now, currentOffset);
        sabbathBeginDuration = nextStart.difference(localNow);
        sabbathEndDuration = _getNextSabbathEnd(
          now,
          currentOffset,
        ).difference(localNow);
      } else {
        // Sabbath hasn't started yet
        sabbathBeginDuration = currentSabbathStart.difference(localNow);
        sabbathEndDuration = currentSabbathEnd.difference(localNow);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      LocationHelper.onAppResumed();
      _updateTimes();
    }
  }

  Future<void> _updateTimes() async {
    try {
      Position? position = await LocationHelper.getCurrentLocation(context);
      if (position != null) {
        await _setLocationData(position);
      } else {
        _useDefaultLocation();
      }
    } catch (e) {
      debugPrint("Location error: $e");
      _useDefaultLocation();
    }
  }

  Future<void> _setLocationData(Position position) async {
    setState(() {
      latitude = position.latitude.toString();
      longitude = position.longitude.toString();
    });

    final now = DateTime.now();
    final timezoneOffset = now.timeZoneOffset;
    setState(() {
      utcOffset = timezoneOffset;
    });

    _calculateSunTimes(position.latitude, position.longitude, utcOffset);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        setState(() {
          city = place.locality ?? 'Unknown City';
          state = place.administrativeArea ?? '';
          country = place.country ?? '';
        });

        await _cacheLocationData(
          place.locality ?? 'Unknown City',
          place.administrativeArea ?? '',
          place.country ?? '',
        );
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
      await _loadCachedLocation();
    }

    // CHANGED: Use safeSetState
    _safeSetState(() {
      if (allLocations.isNotEmpty && allLocations[0]['isCurrent'] == true) {
        allLocations[0] = {
          'city': city,
          'country': country,
          'latitude': latitude,
          'longitude': longitude,
          'timezone': 'current',
          'isCurrent': true,
        };
      }
    });
  }

  void _useDefaultLocation() async {
    await _loadCachedLocation();

    if (city == 'Unknown Location') {
      setState(() {
        latitude = "0.0";
        longitude = "0.0";
        city = "Unknown Location";
        country = "";
        utcOffset = Duration.zero;
      });
    }

    // CHANGED: Use safeSetState
    _safeSetState(() {
      if (allLocations.isNotEmpty && allLocations[0]['isCurrent'] == true) {
        allLocations[0] = {
          'city': city,
          'country': country,
          'latitude': latitude,
          'longitude': longitude,
          'timezone': 'current',
          'isCurrent': true,
        };
      }
    });

    _calculateSunTimes(
      double.tryParse(latitude) ?? 0.0,
      double.tryParse(longitude) ?? 0.0,
      utcOffset,
    );
  }

  void _calculateSunTimes(double latitude, double longitude, Duration offset) {
    try {
      final now = DateTime.now();
      final sunrise = SunCalculator.calculateSunrise(
        now,
        latitude,
        longitude,
        offset,
      );
      final sunset = SunCalculator.calculateSunset(
        now,
        latitude,
        longitude,
        offset,
      );

      setState(() {
        sunriseTime = DateFormat('hh:mm a').format(sunrise);
        sunsetTime = DateFormat('hh:mm a').format(sunset);
      });

      _updateCountdowns();
    } catch (e) {
      debugPrint("Error calculating sun times: $e");
      setState(() {
        sunriseTime = "--:--";
        sunsetTime = "--:--";
      });
    }
  }

  Widget _sabbathCountdown(Duration duration, bool isBeginCounter) {
    final effectiveDuration = duration.isNegative ? Duration.zero : duration;

    // If it's the begin counter and duration is zero, show "SABBATH IS GOING ON"
    if (isBeginCounter && effectiveDuration.inSeconds == 0) {
      return Container(
        child: Column(
          children: [
            SizedBox(height: 25),
            const Text(
              "SABBATH IS GOING ON",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 25),
          ],
        ),
      );
    }

    final hours = effectiveDuration.inHours.toString().padLeft(2, '0');
    final minutes = effectiveDuration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = effectiveDuration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _timeBox(hours, "hrs"),
        const SizedBox(width: 8),
        _timeBox(minutes, "min"),
        const SizedBox(width: 8),
        _timeBox(seconds, "sec"),
      ],
    );
  }

  Widget _timeBox(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 241, 117, 16),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white)),
      ],
    );
  }

  Widget _sabbathSection() {
    // ADDED: Guard against empty locations
    if (allLocations.isEmpty) return SizedBox();

    final now = DateTime.now();
    Duration currentOffset = currentPageIndex == 0
        ? utcOffset
        : _getLocationOffset(allLocations[currentPageIndex]);

    final currentSabbathStart = _getCurrentSabbathStart(now, currentOffset);
    final currentSabbathEnd = _getCurrentSabbathEnd(now, currentOffset);
    final nextSabbathStart = _getNextSabbathStart(now, currentOffset);
    final nextSabbathEnd = _getNextSabbathEnd(now, currentOffset);

    final startDateText = _formatSabbathDate(currentSabbathStart);
    final endDateText = _formatSabbathDate(currentSabbathEnd);
    final nextStartDateText = _formatSabbathDate(nextSabbathStart);
    final nextEndDateText = _formatSabbathDate(nextSabbathEnd);

    final startSunsetText = _getSunsetTime(currentSabbathStart, currentOffset);
    final endSunsetText = _getSunsetTime(currentSabbathEnd, currentOffset);
    final nextStartSunsetText = _getSunsetTime(nextSabbathStart, currentOffset);
    final nextEndSunsetText = _getSunsetTime(nextSabbathEnd, currentOffset);

    return Center(
      child: Column(
        children: [
          Container(
            width: 360,
            margin: const EdgeInsets.only(top: 16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: const Color.fromARGB(255, 255, 159, 80).withOpacity(0.85),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 20.0,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                "SABBATH BEGINS",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                startDateText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                startSunsetText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _sabbathCountdown(
                                _sabbathHasBegun
                                    ? Duration.zero
                                    : sabbathBeginDuration,
                                true, // This is the begins counter
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 150,
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                "SABBATH ENDS",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                endDateText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                endSunsetText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _sabbathCountdown(
                                sabbathEndDuration,
                                false, // This is the ends counter
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_sabbathHasBegun && !_sabbathHasEnded)
            Container(
              width: 360,
              margin: const EdgeInsets.only(top: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: const Color.fromARGB(
                  255,
                  255,
                  159,
                  80,
                ).withOpacity(0.65),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "UPCOMING SABBATH",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "BEGINS",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  nextStartDateText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  nextStartSunsetText,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 100,
                            color: const Color.fromARGB(255, 255, 255, 255),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "ENDS",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  nextEndDateText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  nextEndSunsetText,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(appTitle: 'Sabbath App', appVersion: 'v1.0.0'),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: allLocations.length,
            onPageChanged: (index) {
              setState(() => currentPageIndex = index);
              _updateCountdowns();
            },
            itemBuilder: (context, index) {
              // ADDED: Guard against invalid index
              if (index >= allLocations.length) return SizedBox();

              final location = allLocations[index];
              return KeyedSubtree(
                key: ValueKey('${location['city']}_${location['country']}'),
                child: index == 0
                    ? _buildHomeContent()
                    : _buildLocationDetailScreen(location),
              );
            },
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _buildSwiperIndicators(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwiperIndicators() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          allLocations.length,
          (index) => GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentPageIndex == index
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Builder(
      builder: (context) {
        if (MediaQuery.of(context).orientation == Orientation.portrait) {
          return _portraitHomeWidget();
        } else {
          return _landscapeHomeWidget();
        }
      },
    );
  }

  Widget _portraitHomeWidget() {
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
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
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
                          IconButton(
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddLocationScreen(),
                                ),
                              );

                              if (result != null) {
                                // CHANGED: Use safeSetState
                                _safeSetState(() {
                                  // Filter out duplicates
                                  final newLocations = result
                                      .where(
                                        (newLoc) => !allLocations.any(
                                          (existingLoc) =>
                                              existingLoc['city'] ==
                                                  newLoc['city'] &&
                                              existingLoc['country'] ==
                                                  newLoc['country'],
                                        ),
                                      )
                                      .toList();

                                  allLocations.addAll(newLocations);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        '$city${state.isNotEmpty ? ', $state' : ''}, $country',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    _sabbathSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _landscapeHomeWidget() {
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
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
                          IconButton(
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddLocationScreen(),
                                ),
                              );
                              if (result != null) {
                                // CHANGED: Use safeSetState
                                _safeSetState(() {
                                  allLocations.addAll(result);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        '$city${state.isNotEmpty ? ', $state' : ''}, $country',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    _sabbathSection(),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                flex: 2,
                child: Container(
                  height: 280,
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
    );
  }

  Widget _buildLocationDetailScreen(Map<String, dynamic> location) {
    final latitude =
        double.tryParse(location['latitude']?.toString() ?? '0.0') ?? 0.0;
    final longitude =
        double.tryParse(location['longitude']?.toString() ?? '0.0') ?? 0.0;
    final locationUtcOffset = _getLocationOffset(location);

    final now = DateTime.now().toUtc().add(locationUtcOffset);

    DateTime nextFriday = now;
    while (nextFriday.weekday != DateTime.friday) {
      nextFriday = nextFriday.add(const Duration(days: 1));
    }

    DateTime nextSaturday = nextFriday.add(const Duration(days: 1));

    final beginTime = SunCalculator.calculateSunset(
      nextFriday,
      latitude,
      longitude,
      locationUtcOffset,
    );

    final endTime = SunCalculator.calculateSunset(
      nextSaturday,
      latitude,
      longitude,
      locationUtcOffset,
    );

    final sabbathBeginTime = DateFormat('hh:mm a').format(beginTime);
    final sabbathEndTime = DateFormat('hh:mm a').format(endTime);

    final sabbathBeginDate = _formatSabbathDate(nextFriday);
    final sabbathEndDate = _formatSabbathDate(nextSaturday);

    final currentSunrise = SunCalculator.calculateSunrise(
      now,
      latitude,
      longitude,
      locationUtcOffset,
    );
    final currentSunset = SunCalculator.calculateSunset(
      now,
      latitude,
      longitude,
      locationUtcOffset,
    );

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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _pageController.jumpToPage(0),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                final newLocations =
                    await Navigator.push<List<Map<String, dynamic>>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddLocationScreen(),
                      ),
                    );

                if (newLocations != null) {
                  // CHANGED: Use safeSetState
                  _safeSetState(() {
                    final currentLocation = allLocations.isNotEmpty
                        ? allLocations[0]
                        : null;
                    allLocations = [];
                    if (currentLocation != null) {
                      allLocations.add(currentLocation);
                    }
                    allLocations.addAll(newLocations);
                  });
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "${location['city']}, ${location['country']}",
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                _buildSabbathDetailsCard(
                  sabbathBeginTime,
                  sabbathEndTime,
                  sabbathBeginDate,
                  sabbathEndDate,
                ),
                const SizedBox(height: 20),
                _buildSunTimesCard(
                  DateFormat('hh:mm a').format(currentSunrise),
                  DateFormat('hh:mm a').format(currentSunset),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSabbathDetailsCard(
    String beginTime,
    String endTime,
    String beginDate,
    String endDate,
  ) {
    return Card(
      color: const Color.fromARGB(255, 255, 159, 80).withOpacity(0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTimeTile("SABBATH BEGINS", beginTime, beginDate),
            const Divider(color: Colors.white),
            _buildTimeTile("SABBATH ENDS", endTime, endDate),
          ],
        ),
      ),
    );
  }

  Widget _buildSunTimesCard(String sunrise, String sunset) {
    return Card(
      color: const Color.fromARGB(255, 255, 159, 80).withOpacity(0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSunTimeTile("SUNRISE", sunrise),
            Container(width: 1, height: 60, color: Colors.white),
            _buildSunTimeTile("SUNSET", sunset),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile(String title, String time, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunTimeTile(String title, String time) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
