import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:x_amap_base/x_amap_base.dart';

class PickLocationPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const PickLocationPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<PickLocationPage> createState() => _PickLocationPageState();
}

class _PickLocationPageState extends State<PickLocationPage> {
  static const String _androidAmapKey = 'e26dbf722aba3a0197ae32bc699cc18f';
  static const String _iosAmapKey = '';

  AMapController? _mapController;
  bool _amapInited = false;
  LatLng? _selectedLatLng;

  @override
  void initState() {
    super.initState();

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLatLng = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initAmap(context);
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

  CameraPosition get _initialCameraPosition {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      return CameraPosition(
        target: LatLng(widget.initialLatitude!, widget.initialLongitude!),
        zoom: 16,
      );
    }

    return const CameraPosition(
      target: LatLng(39.909187, 116.397451),
      zoom: 12,
    );
  }

  Set<Marker> _buildMarkers() {
    if (_selectedLatLng == null) return {};

    return {
      Marker(
        position: _selectedLatLng!,
        infoWindowEnable: true,
        infoWindow: const InfoWindow(
          title: 'Selected Point',
          snippet: 'Tap confirm to use this location',
        ),
      ),
    };
  }

  void _confirm() {
    if (_selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tap on the map to choose a point.'),
        ),
      );
      return;
    }

    Navigator.pop<Map<String, dynamic>>(
      context,
      {
        'latitude': _selectedLatLng!.latitude,
        'longitude': _selectedLatLng!.longitude,
      },
    );
  }

  Future<void> _moveToSelected() async {
    if (_selectedLatLng == null || _mapController == null) return;

    await _mapController!.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _selectedLatLng!,
          zoom: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latText = _selectedLatLng == null
        ? '--'
        : _selectedLatLng!.latitude.toStringAsFixed(6);
    final lngText = _selectedLatLng == null
        ? '--'
        : _selectedLatLng!.longitude.toStringAsFixed(6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  AMapWidget(
                    initialCameraPosition: _initialCameraPosition,
                    mapType: MapType.normal,
                    mapLanguage: MapLanguage.english,
                    markers: _buildMarkers(),
                    onMapCreated: (controller) async {
                      _mapController = controller;
                      await _moveToSelected();
                    },
                    onTap: (latLng) {
                      setState(() {
                        _selectedLatLng = latLng;
                      });
                    },
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Tap on the map to adjust the check-in point.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'pick_location_recenter',
                      onPressed: _moveToSelected,
                      child: const Icon(Icons.center_focus_strong_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected: $latText, $lngText',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _confirm,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Confirm Location'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}