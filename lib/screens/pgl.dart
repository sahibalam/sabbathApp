// // ... existing imports and class definitions ...

// class _HomeScreenState extends State<HomeScreen>
//     with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
//   // ... existing properties ...

//   @override
//   Widget build(BuildContext context) {
//     // ... existing build method ...
//   }

//   Widget _sabbathSection() {
//     if (allLocations.isEmpty) return SizedBox();

//     final now = DateTime.now();
//     Duration currentOffset = currentPageIndex == 0
//         ? utcOffset
//         : _getLocationOffset(allLocations[currentPageIndex]);

//     final currentSabbathStart = _getCurrentSabbathStart(now, currentOffset);
//     final currentSabbathEnd = _getCurrentSabbathEnd(now, currentOffset);
//     final nextSabbathStart = _getNextSabbathStart(now, currentOffset);
//     final nextSabbathEnd = _getNextSabbathEnd(now, currentOffset);

//     // ADDED: Format dates with proper suffixes
//     final startDateText = _formatSabbathDate(currentSabbathStart);
//     final endDateText = _formatSabbathDate(currentSabbathEnd);
//     final nextStartDateText = _formatSabbathDate(nextSabbathStart);
//     final nextEndDateText = _formatSabbathDate(nextSabbathEnd);

//     // ADDED: Get formatted sunset times
//     final startSunsetText = _getSunsetTime(currentSabbathStart, currentOffset);
//     final endSunsetText = _getSunsetTime(currentSabbathEnd, currentOffset);
//     final nextStartSunsetText = _getSunsetTime(nextSabbathStart, currentOffset);
//     final nextEndSunsetText = _getSunsetTime(nextSabbathEnd, currentOffset);

//     return Center(
//       child: Column(
//         children: [
//           // ... existing Sabbath countdown card ...
          
//           // CHANGED: Always show upcoming Sabbath during current Sabbath
//           if (_sabbathHasBegun && !_sabbathHasEnded)
//             Container(
//               width: 360,
//               margin: const EdgeInsets.only(top: 16),
//               child: Card(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 color: const Color.fromARGB(255, 255, 159, 80).withOpacity(0.65),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16.0,
//                     vertical: 20.0,
//                   ),
//                   child: Column(
//                     children: [
//                       // ADDED: "UPCOMING SABBATH" header
//                       const Text(
//                         "UPCOMING SABBATH",
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                           color: Colors.white,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       Row(
//                         children: [
//                           // Left section - BEGINS
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 const Text(
//                                   "BEGINS",
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 // ADDED: Formatted date
//                                 Text(
//                                   nextStartDateText,
//                                   style: const TextStyle(
//                                     fontSize: 14,
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 2),
//                                 // ADDED: Sunset time
//                                 Text(
//                                   nextStartSunsetText,
//                                   style: const TextStyle(
//                                     fontSize: 13,
//                                     color: Colors.white,
//                                     fontStyle: FontStyle.italic,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           // Vertical divider
//                           Container(
//                             width: 1,
//                             height: 100,
//                             color: const Color.fromARGB(255, 255, 255, 255),
//                           ),
//                           // Right section - ENDS
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 const Text(
//                                   "ENDS",
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 // ADDED: Formatted date
//                                 Text(
//                                   nextEndDateText,
//                                   style: const TextStyle(
//                                     fontSize: 14,
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 2),
//                                 // ADDED: Sunset time
//                                 Text(
//                                   nextEndSunsetText,
//                                   style: const TextStyle(
//                                     fontSize: 13,
//                                     color: Colors.white,
//                                     fontStyle: FontStyle.italic,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // ADDED: Helper to get formatted sunset time
//   String _getSunsetTime(DateTime date, [Duration? offset]) {
//     try {
//       DateTime sunset = _getSunsetTimeForDate(date, offset ?? utcOffset);
//       return "Sunset: ${DateFormat('hh:mm a').format(sunset)}";
//     } catch (e) {
//       return "Sunset: --:--";
//     }
//   }

//   // ADDED: Helper to format date with suffix
//   String _formatSabbathDate(DateTime date) {
//     final day = DateFormat('d').format(date);
//     final suffix = _getDaySuffix(int.parse(day));
//     final month = DateFormat('MMMM').format(date);
//     final weekday = DateFormat('EEEE').format(date);
//     return '$weekday $day$suffix $month';
//   }

//   // ADDED: Helper to get day suffix
//   String _getDaySuffix(int day) {
//     if (day >= 11 && day <= 13) return 'th';
//     switch (day % 10) {
//       case 1: return 'st';
//       case 2: return 'nd';
//       case 3: return 'rd';
//       default: return 'th';
//     }
//   }

//   // ... rest of the existing code ...
// }