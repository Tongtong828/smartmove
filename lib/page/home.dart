import 'dart:async';

import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../store/store.dart';
import 'addPoint.dart';
import 'current_location.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const String _androidAmapKey = 'e26dbf722aba3a0197ae32bc699cc18f';
  static const String _iosAmapKey = '';

  AMapController? _mapController;
  AMapLocationService? _locationService;
  StreamSubscription<AMapLocationData>? _locationSub;

  AMapLocationData? _currentLocation;
  String _statusText = 'Initializing...';
  String? _errorText;

  bool _amapInited = false;
  bool _locationStarted = false;
  bool _hasMovedCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locationService = AMapLocationService(
      androidKey: _androidAmapKey,
      iosKey: _iosAmapKey,
    );
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
    _locationSub?.cancel();
    _locationService?.dispose();
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
        androidKey: _androidAmapKey,
        iosKey: _iosAmapKey,
      ),
    );

    _amapInited = true;
  }

  Future<void> _startLocation() async {
    _locationStarted = true;

    setState(() {
      _statusText = 'Starting location...';
      _errorText = null;
    });

    final first = await _locationService?.getCurrentLocation();

    if (!mounted) return;

    if (first != null) {
      setState(() {
        _currentLocation = first;
        _statusText = 'Current location acquired';
        _errorText = null;
      });

      await _moveCameraToCurrent();
      _hasMovedCamera = true;
    } else {
      setState(() {
        _statusText = 'Failed to get current location';
        _errorText = 'Location returned no valid result.';
      });
    }

    await _locationSub?.cancel();
    _locationSub = _locationService?.stream.listen((loc) {
      if (!mounted) return;

      setState(() {
        _currentLocation = loc;
        _statusText = 'Location updated';
        _errorText = null;
      });

      if (!_hasMovedCamera) {
        _moveCameraToCurrent();
        _hasMovedCamera = true;
      }
    });

    await _locationService?.startContinuousLocation();
  }

  Future<void> _refreshCurrentLocation() async {
    setState(() {
      _statusText = 'Refreshing current location...';
      _errorText = null;
    });

    final loc = await _locationService?.getCurrentLocation();

    if (!mounted) return;

    if (loc == null) {
      setState(() {
        _statusText = 'Refresh failed';
        _errorText = 'Location refresh failed.';
      });
      return;
    }

    setState(() {
      _currentLocation = loc;
      _statusText = 'Current location refreshed';
      _errorText = null;
    });

    await _moveCameraToCurrent();
    _hasMovedCamera = true;
  }

  Future<void> _moveCameraToCurrent() async {
    if (_mapController == null || _currentLocation == null) return;

    await _mapController!.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
          ),
          zoom: 16,
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (_currentLocation != null) {
      markers.add(
        Marker(
          position: LatLng(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
          ),
          infoWindowEnable: true,
          infoWindow: InfoWindow(
            title: 'Current Location',
            snippet: _currentLocation!.displayAddress,
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
            snippet: record.address,
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
          initialLatitude: _currentLocation?.latitude,
          initialLongitude: _currentLocation?.longitude,
          initialAddress: _currentLocation?.displayAddress,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CheckInStore.instance,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('City Check-in Map'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
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
                          bottom: 16,
                          child: FloatingActionButton.small(
                            heroTag: 'recenter_btn',
                            onPressed: _refreshCurrentLocation,
                            child: const Icon(Icons.my_location_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _errorText!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _goToAddPoint,
                      icon: const Icon(Icons.add_location_alt_rounded),
                      label: const Text('Add Check-in'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}