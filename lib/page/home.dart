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
  String? _errorText;

  bool _amapInited = false;
  bool _locationStarted = false;
  bool _hasMovedCamera = false;
  bool _isLocating = false;

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
      _tryRefreshCurrentLocation();
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
      _errorText = null;
    });

    final first = await _locationService?.getCurrentLocation();

    if (!mounted) return;

    if (first != null) {
      setState(() {
        _currentLocation = first;
      });

      await _moveCameraToCurrent(forceZoom: true);
      _hasMovedCamera = true;
    } else {
      setState(() {
        _errorText = 'Location is currently unavailable.';
      });
    }

    await _locationSub?.cancel();
    _locationSub = _locationService?.stream.listen(
      (loc) {
        if (!mounted) return;

        setState(() {
          _currentLocation = loc;
          _errorText = null;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _errorText = 'Live location updates failed.';
        });
      },
    );

    await _locationService?.startContinuousLocation();
  }

  Future<void> _tryRefreshCurrentLocation() async {
    final loc = await _locationService?.getCurrentLocation();

    if (!mounted) return;

    if (loc != null) {
      setState(() {
        _currentLocation = loc;
        _errorText = null;
      });
    }
  }

  Future<void> _moveCameraToCurrent({bool forceZoom = false}) async {
    if (_mapController == null || _currentLocation == null) return;

    await _mapController!.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
          ),
          zoom: forceZoom ? 15.5 : 14.5,
        ),
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    if (_isLocating) return;

    // If live location already exists, just move the camera immediately.
    if (_currentLocation != null) {
      await _moveCameraToCurrent(forceZoom: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Moved to current location.'),
        ),
      );
      return;
    }

    // Fallback: try to get location once only when no cached location exists.
    setState(() {
      _isLocating = true;
      _errorText = null;
    });

    final loc = await _locationService?.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      _isLocating = false;
    });

    if (loc == null) {
      setState(() {
        _errorText = 'Unable to get the current location.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get the current location.'),
        ),
      );
      return;
    }

    setState(() {
      _currentLocation = loc;
      _errorText = null;
    });

    await _moveCameraToCurrent(forceZoom: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Moved to current location.'),
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
            title: const Text('City Memory Map'),
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
                              '${CheckInStore.instance.records.length} saved places',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        // Recenter button: move back to the latest known location.
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(18),
                            elevation: 3,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: _goToMyLocation,
                              child: SizedBox(
                                width: 54,
                                height: 54,
                                child: _isLocating
                                    ? const Padding(
                                        padding: EdgeInsets.all(14),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                        ),
                                      )
                                    : const Icon(Icons.my_location_rounded),
                              ),
                            ),
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
                      label: const Text('Add Place'),
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