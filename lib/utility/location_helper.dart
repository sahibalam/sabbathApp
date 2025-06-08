import 'dart:async';
import 'dart:developer'; // For PlatformException
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class LocationHelper {
  static Completer<bool?>? _gpsDialogCompleter;
  static Future<Position?> getCurrentLocation(BuildContext context) async {
    try {
      // Clear any existing completer
      _gpsDialogCompleter?.complete(null);
      _gpsDialogCompleter = null;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('Location services disabled');

        _gpsDialogCompleter = Completer<bool?>();

        showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('GPS is disabled'),
            content: const Text(
              'Please enable GPS to get accurate location data.',
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  _gpsDialogCompleter?.complete(false);
                  _gpsDialogCompleter = null;
                },
              ),
              TextButton(
                child: const Text('Enable GPS'),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  _gpsDialogCompleter?.complete(true);
                  _gpsDialogCompleter = null;
                },
              ),
            ],
          ),
        );

        final shouldEnable = await _gpsDialogCompleter!.future;
        if (shouldEnable == true) {
          await Geolocator.openLocationSettings();
          // When we return, the app will resume and we'll check status again
          return null;
        }
        return null;
      }

      // Rest of your existing permission checking and position fetching code
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          log('Location permission denied');
          return null;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      ).timeout(const Duration(seconds: 10));

      return position;
    } catch (e) {
      log('Error getting location: $e');
      return null;
    }
  }

  static void onAppResumed() {
    // If we have a pending GPS dialog completer, complete it
    _gpsDialogCompleter?.complete(null);
    _gpsDialogCompleter = null;
  }
}
