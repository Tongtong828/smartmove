import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription<Position>? _subscription;

  String status = 'Idle';
  String? errorText;
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    _startLocationTest();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTest() async {
    _subscription?.cancel();

    setState(() {
      status = 'Checking location service...';
      errorText = null;
      currentPosition = null;
    });

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        status = 'Location service disabled';
        errorText = 'Please turn on GPS / Location service.';
      });
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      setState(() {
        status = 'Permission denied';
        errorText = 'Location permission was denied.';
      });
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        status = 'Permission denied forever';
        errorText = 'Please enable location permission in app settings.';
      });
      return;
    }

    // 先尝试 last known
    setState(() {
      status = 'Getting last known position...';
    });

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        setState(() {
          currentPosition = lastKnown;
          status = 'Last known position acquired';
        });
      }
    } catch (_) {}

    // Android  LocationManager
    var androidSettings = AndroidSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 3,
  forceLocationManager: true,
);

  
    setState(() {
      status = 'Getting current position (LocationManager)...';
    });

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: androidSettings,
      ).timeout(const Duration(seconds: 20));

      setState(() {
        currentPosition = pos;
        status = 'Current position acquired';
      });
    } on TimeoutException {
      setState(() {
        status = 'Timeout';
        errorText =
            'Still waiting for GPS fix. Try going outdoors, near a window, and keep precise location on.';
      });
    } catch (e) {
      setState(() {
        status = 'getCurrentPosition failed';
        errorText = '$e';
      });
    }

    // location updated
    setState(() {
      status = 'Listening to location updates...';
    });

    _subscription = Geolocator.getPositionStream(
      locationSettings: androidSettings,
    ).listen(
      (pos) {
        setState(() {
          currentPosition = pos;
          status = 'Listening...';
          errorText = null;
        });
      },
      onError: (e) {
        setState(() {
          errorText = '$e';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Test'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $status'),
            const SizedBox(height: 16),
            if (currentPosition != null) ...[
              Text('Latitude: ${currentPosition!.latitude}'),
              const SizedBox(height: 8),
              Text('Longitude: ${currentPosition!.longitude}'),
              const SizedBox(height: 8),
              Text('Accuracy: ${currentPosition!.accuracy} m'),
              const SizedBox(height: 8),
              Text('Speed: ${currentPosition!.speed} m/s'),
              const SizedBox(height: 8),
              Text('Timestamp: ${currentPosition!.timestamp}'),
            ] else
              const Text('No location yet'),
            const SizedBox(height: 24),
            if (errorText != null)
              Text(
                errorText!,
                style: const TextStyle(color: Colors.red),
              ),
            const Spacer(),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton(
                  onPressed: _startLocationTest,
                  child: const Text('Retry'),
                ),
                OutlinedButton(
                  onPressed: Geolocator.openLocationSettings,
                  child: const Text('Open Location Settings'),
                ),
                OutlinedButton(
                  onPressed: Geolocator.openAppSettings,
                  child: const Text('Open App Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}