import 'dart:async';
import 'dart:io';

import 'package:amap_flutter_location_plus_x/amap_flutter_location_plus.dart';
import 'package:amap_flutter_location_plus_x/amap_location_option.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AMapLocationData {
  final double latitude;
  final double longitude;
  final String address;
  final String province;
  final String city;
  final String district;
  final String street;
  final String adCode;
  final double accuracy;

  const AMapLocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.province,
    required this.city,
    required this.district,
    required this.street,
    required this.adCode,
    required this.accuracy,
  });

  String get displayAddress {
    if (address.trim().isNotEmpty) return address;

    final parts = [street, district, city, province]
        .where((e) => e.trim().isNotEmpty)
        .toList();

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    return 'Address unavailable';
  }
}

class AMapLocationService {
  AMapLocationService({
    required String androidKey,
    required String iosKey,
  })  : _androidKey = androidKey,
        _iosKey = iosKey {
    _plugin = AMapFlutterLocation();

    AMapFlutterLocation.updatePrivacyShow(true, true);
    AMapFlutterLocation.updatePrivacyAgree(true);
    AMapFlutterLocation.setApiKey(_androidKey, _iosKey);
  }

  final String _androidKey;
  final String _iosKey;

  late final AMapFlutterLocation _plugin;
  StreamSubscription<Map<String, Object>>? _sub;

  final StreamController<AMapLocationData> _controller =
      StreamController<AMapLocationData>.broadcast();

  Stream<AMapLocationData> get stream => _controller.stream;

  Future<bool> requestPermission() async {
    var locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) {
      locationStatus = await Permission.location.request();
    }

    if (!locationStatus.isGranted) {
      return false;
    }

    if (Platform.isAndroid) {
      var whenInUse = await Permission.locationWhenInUse.status;
      if (!whenInUse.isGranted) {
        whenInUse = await Permission.locationWhenInUse.request();
      }
    }

    return true;
  }

  void _setSingleLocationOption() {
    final option = AMapLocationOption();

    option.onceLocation = true;
    option.needAddress = true;

    option.geoLanguage = GeoLanguage.EN;

    option.locationMode = AMapLocationMode.Hight_Accuracy;
    option.androidLocationScene = AMapAndroidLocationScene.SignIn;
    option.locationInterval = 2000;
    option.distanceFilter = -1;
    option.desiredAccuracy = DesiredAccuracy.Best;
    option.pausesLocationUpdatesAutomatically = false;

    _plugin.setLocationOption(option);
  }

  void _setContinuousLocationOption() {
    final option = AMapLocationOption();

    option.onceLocation = false;
    option.needAddress = true;


    option.geoLanguage = GeoLanguage.EN;

    option.locationMode = AMapLocationMode.Hight_Accuracy;
    option.androidLocationScene = AMapAndroidLocationScene.SignIn;
    option.locationInterval = 3000;
    option.distanceFilter = -1;
    option.desiredAccuracy = DesiredAccuracy.Best;
    option.pausesLocationUpdatesAutomatically = false;

    _plugin.setLocationOption(option);
  }

  AMapLocationData? _parse(Map<String, Object> raw) {
    try {
      final lat = (raw['latitude'] as num?)?.toDouble();
      final lng = (raw['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) return null;

      final accuracy = (raw['accuracy'] as num?)?.toDouble() ?? 0.0;

      final address = (raw['address'] as String?) ?? '';
      final province = (raw['province'] as String?) ?? '';
      final city = (raw['city'] as String?) ?? '';
      final district = (raw['district'] as String?) ?? '';
      final street = (raw['street'] as String?) ?? '';
      final adCode = (raw['adCode'] as String?) ?? '';

      return AMapLocationData(
        latitude: lat,
        longitude: lng,
        address: address,
        province: province,
        city: city,
        district: district,
        street: street,
        adCode: adCode,
        accuracy: accuracy,
      );
    } catch (e) {
      debugPrint('AMap parse error: $e');
      return null;
    }
  }

  Future<AMapLocationData?> getCurrentLocation({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final granted = await requestPermission();
    if (!granted) return null;

    _setSingleLocationOption();

    final completer = Completer<AMapLocationData?>();

    StreamSubscription<Map<String, Object>>? tempSub;
    tempSub = _plugin.onLocationChanged().listen((raw) {
      final parsed = _parse(raw);
      if (parsed != null && !completer.isCompleted) {
        completer.complete(parsed);
      }
    });

    _plugin.startLocation();

    try {
      final result = await completer.future.timeout(timeout);
      _plugin.stopLocation();
      await tempSub.cancel();
      return result;
    } catch (_) {
      _plugin.stopLocation();
      await tempSub.cancel();
      return null;
    }
  }

  Future<void> startContinuousLocation() async {
    final granted = await requestPermission();
    if (!granted) return;

    await _sub?.cancel();
    _setContinuousLocationOption();

    _sub = _plugin.onLocationChanged().listen((raw) {
      final parsed = _parse(raw);
      if (parsed != null) {
        _controller.add(parsed);
      }
    });

    _plugin.startLocation();
  }

  Future<void> stopContinuousLocation() async {
    _plugin.stopLocation();
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> dispose() async {
    await stopContinuousLocation();
    await _controller.close();
    _plugin.destroy();
  }
}