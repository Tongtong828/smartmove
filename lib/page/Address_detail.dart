import 'dart:convert';

import 'package:http/http.dart' as http;

class AMapRegeoService {
  AMapRegeoService({
    required this.webKey,
  });

  final String webKey;

  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      'https://restapi.amap.com/v3/geocode/regeo'
      '?output=JSON'
      '&location=$longitude,$latitude'
      '&extensions=base'
      '&radius=1000'
      '&key=$webKey',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return null;
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (data['status']?.toString() != '1') {
      return null;
    }

    final regeo = data['regeocode'];
    if (regeo is! Map<String, dynamic>) {
      return null;
    }

    final formattedAddress = regeo['formatted_address']?.toString();
    if (formattedAddress != null && formattedAddress.trim().isNotEmpty) {
      return formattedAddress;
    }

    final component = regeo['addressComponent'];
    if (component is Map<String, dynamic>) {
      final province = component['province']?.toString() ?? '';
      final cityValue = component['city'];
      final city = cityValue is List ? '' : (cityValue?.toString() ?? '');
      final district = component['district']?.toString() ?? '';
      final township = component['township']?.toString() ?? '';
      final streetNumber = component['streetNumber'];

      String street = '';
      String number = '';

      if (streetNumber is Map<String, dynamic>) {
        street = streetNumber['street']?.toString() ?? '';
        number = streetNumber['number']?.toString() ?? '';
      }

      final parts = [province, city, district, township, street, number]
          .where((e) => e.trim().isNotEmpty)
          .toList();

      if (parts.isNotEmpty) {
        return parts.join('');
      }
    }

    return null;
  }
}