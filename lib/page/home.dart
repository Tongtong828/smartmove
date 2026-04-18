import 'dart:async';
import 'dart:math' as math;

import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../model/route_point.dart';
import '../model/sport_session.dart';
import '../model/sport_type.dart';
import '../widget/select_list.dart';
import '../widget/stats_panel.dart';
import 'summary.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;

  Position? _currentPosition;
  Position? _lastTrackedPosition;

  String _statusText = 'Checking permission...';
  String? _errorText;

  bool _amapInited = false;

  bool isTracking = false;
  SportType? selectedType;

  DateTime? _startedAt;
  int _elapsedSeconds = 0;
  double _distanceKm = 0.0;
  int _comfortScore = 80;

  final List<RoutePoint> _routePoints = [];

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _initAmap(BuildContext context) {
    if (_amapInited) return;

    AMapInitializer.init(
      context,
      apiKey: const AMapApiKey(
        androidKey: '替换成你新的高德Key',
        iosKey: '',
      ),
    );

    AMapInitializer.updatePrivacyAgree(
      const AMapPrivacyStatement(
        hasContains: true,
        hasShow: true,
        hasAgree: true,
      ),
    );

    _amapInited = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initAmap(context);
    if (_positionSubscription == null) {
      _startLocation();
    }
  }

  Future<void> _startLocation() async {
    setState(() {
      _statusText = 'Checking location service...';
      _errorText = null;
    });

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusText = 'Location service disabled';
        _errorText = 'Please turn on GPS / Location service.';
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
        _errorText = 'Location permission was denied.';
      });
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _statusText = 'Permission denied forever';
        _errorText = 'Please enable location permission in app settings.';
      });
      return;
    }

    final settings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
      forceLocationManager: true,
    );

    setState(() {
      _statusText = 'Getting current position...';
    });

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        setState(() {
          _currentPosition = lastKnown;
          _statusText = 'Last known position acquired';
        });
        await _moveCameraToCurrent();
      }
    } catch (_) {}

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      ).timeout(
        const Duration(seconds: 30),
      );

      setState(() {
        _currentPosition = current;
        _statusText = 'Location acquired';
        _errorText = null;
      });

      await _moveCameraToCurrent();
    } on TimeoutException {
      setState(() {
        _statusText = 'Timeout';
        _errorText =
            'Still waiting for GPS fix. Try near a window or outdoors.';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Location error';
        _errorText = '$e';
      });
    }

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((pos) async {
      setState(() {
        _currentPosition = pos;
        _statusText = 'Listening...';
        _errorText = null;
      });

      if (isTracking) {
        _appendTrackPoint(pos);
      }

      await _moveCameraToCurrent();
    });
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
          zoom: 17,
        ),
      ),
    );
  }

  void _showSelectSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SelectListSheet(
        onSelected: _startTracking,
      ),
    );
  }

  void _startTracking(SportType type) {
    if (_currentPosition == null) {
      setState(() {
        _errorText = 'Wait for location first, then start the activity.';
      });
      return;
    }

    _timer?.cancel();

    setState(() {
      selectedType = type;
      isTracking = true;
      _startedAt = DateTime.now();
      _elapsedSeconds = 0;
      _distanceKm = 0.0;
      _comfortScore = 80;
      _routePoints.clear();
      _lastTrackedPosition = _currentPosition;
      _errorText = null;
    });

    _appendTrackPoint(_currentPosition!, forceAdd: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !isTracking) return;
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _appendTrackPoint(Position pos, {bool forceAdd = false}) {
    if (_lastTrackedPosition == null) {
      _lastTrackedPosition = pos;
    }

    final previous = _lastTrackedPosition!;
    final meters = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      pos.latitude,
      pos.longitude,
    );

    if (forceAdd || meters >= 2) {
      if (!forceAdd) {
        _distanceKm += meters / 1000;
      }

      _routePoints.add(
        RoutePoint(
          latitude: pos.latitude,
          longitude: pos.longitude,
          timestamp: DateTime.now(),
          comfortLevel: _estimateComfort(pos),
        ),
      );

      _lastTrackedPosition = pos;

      setState(() {
        _comfortScore = (_estimateComfort(pos) * 100).round();
      });
    }
  }

  double _estimateComfort(Position pos) {
    final speed = pos.speed < 0 ? 0.0 : pos.speed;
    final accuracy = pos.accuracy < 0 ? 100.0 : pos.accuracy;

    double score = 0.85;

    if (accuracy > 30) score -= 0.15;
    if (accuracy > 50) score -= 0.10;

    if (selectedType == SportType.walking) {
      if (speed > 2.2) score -= 0.10;
    } else if (selectedType == SportType.running) {
      if (speed > 4.5) score -= 0.08;
    } else if (selectedType == SportType.cycling) {
      if (speed > 8.0) score -= 0.08;
    }

    return score.clamp(0.35, 0.95);
  }

  Future<void> _finishTracking() async {
    if (selectedType == null || _startedAt == null) return;

    _timer?.cancel();

    final session = SportSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: selectedType!,
      startedAt: _startedAt!,
      endedAt: DateTime.now(),
      distanceKm: _distanceKm,
      averagePace: _paceText(),
      comfortScore: _comfortScore,
      points: List<RoutePoint>.from(_routePoints),
    );

    SessionStore.addSession(session);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryPage(session: session),
      ),
    );

    if (!mounted) return;

    setState(() {
      isTracking = false;
      selectedType = null;
      _startedAt = null;
      _elapsedSeconds = 0;
      _distanceKm = 0.0;
      _comfortScore = 80;
      _routePoints.clear();
      _lastTrackedPosition = null;
    });
  }

  String _durationText() {
    final hours = (_elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _distanceText() {
    return '${_distanceKm.toStringAsFixed(2)} km';
  }

  String _paceText() {
    if (_distanceKm <= 0 || _elapsedSeconds == 0 || selectedType == null) {
      return '--';
    }

    if (selectedType == SportType.cycling) {
      final hours = _elapsedSeconds / 3600;
      final speed = _distanceKm / math.max(hours, 0.0001);
      return '${speed.toStringAsFixed(1)} km/h';
    }

    final paceMinutes = (_elapsedSeconds / 60) / _distanceKm;
    final paceMin = paceMinutes.floor();
    final paceSec =
        ((paceMinutes - paceMin) * 60).round().toString().padLeft(2, '0');
    return '$paceMin\'$paceSec"/km';
  }

  @override
  Widget build(BuildContext context) {
    final latitude = _currentPosition?.latitude;
    final longitude = _currentPosition?.longitude;
    final accuracy = _currentPosition?.accuracy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartMove'),
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
                        zoom: 15,
                      ),
                      mapType: MapType.normal,
                      mapLanguage: MapLanguage.english,
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
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isTracking
                            ? '${selectedType?.label ?? ''} in progress'
                            : 'Home Map',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'recenter_btn',
                      onPressed: _moveCameraToCurrent,
                      child: const Icon(Icons.my_location),
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
                    Row(
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(_statusText),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Latitude',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          latitude == null ? '--' : latitude.toStringAsFixed(6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Longitude',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          longitude == null
                              ? '--'
                              : longitude.toStringAsFixed(6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Accuracy',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          accuracy == null
                              ? '--'
                              : '${accuracy.toStringAsFixed(1)} m',
                        ),
                      ],
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
            const SizedBox(height: 12),
            StatsPanel(
              isTracking: isTracking,
              sportType: selectedType,
              durationText: _durationText(),
              distanceText: _distanceText(),
              paceText: _paceText(),
              comfortScore: _comfortScore,
            ),
            const SizedBox(height: 16),
            if (!isTracking)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showSelectSheet,
                  icon: const Icon(Icons.add),
                  label: const Text('Start Activity'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _finishTracking,
                  icon: const Icon(Icons.stop),
                  label: const Text('Finish'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}