// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:intl/intl.dart';
// import '../../spa/suncal.dart';
// import '../../utility/location_helper.dart';

// class FutureDateScreen extends StatefulWidget {
//   const FutureDateScreen({super.key});

//   @override
//   State<FutureDateScreen> createState() => _FutureDateScreenState();
// }

// class _FutureDateScreenState extends State<FutureDateScreen>
//     with WidgetsBindingObserver {
//   String latitude = "";
//   String longitude = "";
//   late String day;
//   late String month;
//   late String year;
//   String sunriseTime = "--:--";
//   String sunsetTime = "--:--";

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     fetchLocation();
//     final now = DateTime.now();
//     day = DateFormat('d').format(now);
//     month = DateFormat('MMMM').format(now);
//     year = DateFormat('y').format(now);
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       fetchLocation();
//     }
//   }

//   void fetchLocation() async {
//     Position? position = await LocationHelper.getCurrentLocation(context);
//     if (position != null) {
//       setState(() {
//         latitude = position.latitude.toString();
//         longitude = position.longitude.toString();

//         final now = DateTime.now();
//         final sunrise = SunCalculator.calculateSunrise(
//           now,
//           position.latitude,
//           position.longitude,
//         );
//         final sunset = SunCalculator.calculateSunset(
//           now,
//           position.latitude,
//           position.longitude,
//         );

//         final localSunrise = sunrise.toLocal();
//         final localSunset = sunset.toLocal();

//         sunriseTime = DateFormat('hh:mm a').format(localSunrise);
//         sunsetTime = DateFormat('hh:mm a').format(localSunset);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Builder(
//         builder: (context) {
//           if (MediaQuery.of(context).orientation == Orientation.portrait) {
//             return portraitWidget();
//           } else {
//             return landscapeWidget();
//           }
//         },
//       ),
//     );
//   }

//   Widget portraitWidget() {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Color(0xFFF4732F),
//             Color(0xFFFBB13A),
//             Color(0xFFFBB13A),
//             Color(0xFFF4732F),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.only(top: 40.0),
//           child: Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16.0,
//                   vertical: 12.0,
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: const [
//                     Icon(Icons.menu, color: Colors.white, size: 28),
//                     SizedBox(width: 40),
//                     Icon(
//                       Icons.notifications_none,
//                       color: Colors.white,
//                       size: 28,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 30),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: TextField(
//                   decoration: InputDecoration(
//                     filled: true,
//                     fillColor: Colors.white,
//                     hintText: "Search location...",
//                     prefixIcon: Icon(
//                       Icons.location_on,
//                       color: Colors.grey[700],
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12.0),
//                       borderSide: BorderSide.none,
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(
//                       vertical: 0,
//                       horizontal: 12,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 36),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 32.0),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     _dateOverlay(day),
//                     _dateOverlay(month),
//                     _dateOverlay(year),
//                     _iconOverlay(),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 48),
//               Container(
//                 width: 340,
//                 height: 280,
//                 decoration: BoxDecoration(
//                   color: Colors.orange.shade400,
//                   borderRadius: BorderRadius.circular(20.0),
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(
//                             Icons.wb_sunny,
//                             color: Colors.white,
//                             size: 80,
//                           ),
//                           const SizedBox(height: 16),
//                           Text(
//                             sunriseTime,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(width: 1, height: 180, color: Colors.white),
//                     Expanded(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           const Icon(
//                             Icons.nights_stay,
//                             color: Colors.white,
//                             size: 80,
//                           ),
//                           const SizedBox(height: 16),
//                           Text(
//                             sunsetTime,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget landscapeWidget() {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Color(0xFFF4732F),
//             Color(0xFFFBB13A),
//             Color(0xFFFBB13A),
//             Color(0xFFF4732F),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 flex: 3,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 24),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: const [
//                           Icon(Icons.menu, color: Colors.white, size: 28),
//                           Icon(
//                             Icons.notifications_none,
//                             color: Colors.white,
//                             size: 28,
//                           ),
//                         ],
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 36),
//                       child: TextField(
//                         decoration: InputDecoration(
//                           filled: true,
//                           fillColor: Colors.white,
//                           hintText: "Search location...",
//                           prefixIcon: Icon(
//                             Icons.location_on,
//                             color: Colors.grey,
//                           ),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12.0),
//                             borderSide: BorderSide.none,
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(
//                             vertical: 0,
//                             horizontal: 12,
//                           ),
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 48),
//                       child: Row(
//                         children: [
//                           _dateOverlay(day),
//                           _dateOverlay(month),
//                           _dateOverlay(year),
//                           _iconOverlay(),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 40),
//               Expanded(
//                 flex: 2,
//                 child: Container(
//                   height: 280,
//                   decoration: BoxDecoration(
//                     color: Colors.orange.shade400,
//                     borderRadius: BorderRadius.circular(20.0),
//                   ),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Icon(
//                               Icons.wb_sunny,
//                               color: Colors.white,
//                               size: 80,
//                             ),
//                             const SizedBox(height: 16),
//                             Text(
//                               sunriseTime,
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Container(width: 1, height: 180, color: Colors.white),
//                       Expanded(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Icon(
//                               Icons.nights_stay,
//                               color: Colors.white,
//                               size: 80,
//                             ),
//                             const SizedBox(height: 16),
//                             Text(
//                               sunsetTime,
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _dateOverlay(String text) {
//     return Container(
//       width: 52,
//       height: 48,
//       margin: const EdgeInsets.symmetric(horizontal: 6.0),
//       color: Colors.deepOrange,
//       alignment: Alignment.center,
//       child: Text(
//         text,
//         style: const TextStyle(
//           color: Colors.white,
//           fontSize: 16,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   Widget _iconOverlay() {
//     return Container(
//       width: 52,
//       height: 48,
//       margin: const EdgeInsets.symmetric(horizontal: 6.0),
//       color: Colors.deepOrange,
//       child: const Icon(Icons.calendar_today, color: Colors.white),
//     );
//   }
// }
