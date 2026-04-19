import 'dart:async';

import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../store/store.dart';
import 'addPoint.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  AMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;

  Position? _currentPosition;
  String _statusText = 'Initializing...';
  String? _errorText;

  bool _amapInited = false;
  bool _locationStarted = false;
  bool _hasMovedCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initAmap(context);

    if (!_locationStarted) {
      _startLocation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCurrentLocation();
    }
  }

  void _initAmap(BuildContext context) {
    if (_amapInited) return;

    AMapInitializer.updatePrivacyAgree(
      const AMapPrivacyStatement(
        hasContains: true,
        hasShow: true,
        hasAgree: true,
      ),
    );

    AMapInitializer.init(
      context,
      apiKey: const AMapApiKey(
        androidKey: '21c52760a4cb63f4b3682cf50e74e41d',
        iosKey: '',
      ),
    );

    _amapInited = true;
  }

  Future<void> _startLocation() async {
    _locationStarted = true;

    setState(() {
      _statusText = 'Checking location...';
      _errorText = null;
    });

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusText = 'Location service disabled';
        _errorText = 'Please turn on GPS / Location.';
      });
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      setState(() {
        _statusText = 'Permission denied';
        _errorText = 'Location permission denied.';
      });
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _statusText = 'Permission denied forever';
        _errorText = 'Please enable location permission in settings.';
      });
      return;
    }

    setState(() {
      _statusText = 'Listening...';
      _errorText = null;
    });

    await _positionSubscription?.cancel();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      (pos) {
        if (!mounted) return;

        setState(() {
          _currentPosition = pos;
          _statusText = 'Location updated';
          _errorText = null;
        });

        if (!_hasMovedCamera) {
          _moveCameraToCurrent();
          _hasMovedCamera = true;
        }
      },
      onError: (e) {
        if (!mounted) return;

        setState(() {
          _statusText = 'Location error';
          _errorText = '$e';
        });
      },
    );

    await _refreshCurrentLocation();
  }

  Future<void> _refreshCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = pos;
        _statusText = 'Current location acquired';
        _errorText = null;
      });

      await _moveCameraToCurrent();
      _hasMovedCamera = true;
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _statusText = 'Failed to get location';
        _errorText = '$e';
      });
    }
  }

  Future<void> _moveCameraToCurrent() async {
    if (_mapController == null || _currentPosition == null) return;

    await _mapController!.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          zoom: 16,
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (_currentPosition != null) {
      markers.add(
        Marker(
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindowEnable: true,
          infoWindow: const InfoWindow(
            title: 'Current Position',
            snippet: 'You are here',
          ),
        ),
      );
    }

    for (final record in CheckInStore.instance.records) {
      markers.add(
        Marker(
          position: LatLng(record.latitude, record.longitude),
          infoWindowEnable: true,
          infoWindow: InfoWindow(
            title: record.title,
            snippet: record.dateTimeLabel,
          ),
        ),
      );
    }

    return markers;
  }

  Future<void> _goToAddPoint() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPointPage(
          initialLatitude: _currentPosition?.latitude,
          initialLongitude: _currentPosition?.longitude,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final lat = _currentPosition?.latitude;
    final lng = _currentPosition?.longitude;

    return AnimatedBuilder(
      animation: CheckInStore.instance,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('City Check-in Map'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AMapWidget(
                          initialCameraPosition: const CameraPosition(
                            target: LatLng(39.909187, 116.397451),
                            zoom: 12,
                          ),
                          mapType: MapType.normal,
                          mapLanguage: MapLanguage.english,
                          markers: _buildMarkers(),
                          onMapCreated: (controller) async {
                            _mapController = controller;
                            await _moveCameraToCurrent();
                          },
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${CheckInStore.instance.records.length} saved check-ins',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 86,
                        child: FloatingActionButton.small(
                          heroTag: 'recenter_btn',
                          onPressed: _refreshCurrentLocation,
                          child: const Icon(Icons.my_location_rounded),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.extended(
                          heroTag: 'add_btn',
                          onPressed: _goToAddPoint,
                          icon: const Icon(Icons.add_location_alt_rounded),
                          label: const Text('Add Check-in'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _row('Status', _statusText),
                        const SizedBox(height: 8),
                        _row(
                          'Latitude',
                          lat == null ? '--' : lat.toStringAsFixed(6),
                        ),
                        const SizedBox(height: 8),
                        _row(
                          'Longitude',
                          lng == null ? '--' : lng.toStringAsFixed(6),
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorText!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(String title, String value) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Text(value),
      ],
    );
  }
}