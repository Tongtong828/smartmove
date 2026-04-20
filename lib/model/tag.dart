import 'package:flutter/material.dart';

class PlaceTagDefinition {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const PlaceTagDefinition({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const String customTagPrefix = 'custom:';

const List<PlaceTagDefinition> availableTags = [
  PlaceTagDefinition(
    key: 'home',
    label: 'Home',
    icon: Icons.home_rounded,
    color: Color(0xFF5C6BC0),
  ),
  PlaceTagDefinition(
    key: 'school',
    label: 'School',
    icon: Icons.school_rounded,
    color: Color(0xFF3949AB),
  ),
  PlaceTagDefinition(
    key: 'work',
    label: 'Work',
    icon: Icons.work_rounded,
    color: Color(0xFF6D4C41),
  ),
  PlaceTagDefinition(
    key: 'study',
    label: 'Study',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF00897B),
  ),
  PlaceTagDefinition(
    key: 'food',
    label: 'Food',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFE53935),
  ),
  PlaceTagDefinition(
    key: 'coffee',
    label: 'Coffee',
    icon: Icons.local_cafe_rounded,
    color: Color(0xFF8D6E63),
  ),
  PlaceTagDefinition(
    key: 'shopping',
    label: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFFFB8C00),
  ),
  PlaceTagDefinition(
    key: 'park',
    label: 'Park',
    icon: Icons.park_rounded,
    color: Color(0xFF43A047),
  ),
  PlaceTagDefinition(
    key: 'museum',
    label: 'Museum',
    icon: Icons.museum_rounded,
    color: Color(0xFF7E57C2),
  ),
  PlaceTagDefinition(
    key: 'photo',
    label: 'Photo Spot',
    icon: Icons.photo_camera_rounded,
    color: Color(0xFF039BE5),
  ),
  PlaceTagDefinition(
    key: 'date',
    label: 'Date',
    icon: Icons.favorite_rounded,
    color: Color(0xFFD81B60),
  ),
  PlaceTagDefinition(
    key: 'sports',
    label: 'Sports',
    icon: Icons.sports_basketball_rounded,
    color: Color(0xFF00ACC1),
  ),
  PlaceTagDefinition(
    key: 'travel',
    label: 'Travel',
    icon: Icons.flight_takeoff_rounded,
    color: Color(0xFF1E88E5),
  ),
  PlaceTagDefinition(
    key: 'family',
    label: 'Family',
    icon: Icons.people_alt_rounded,
    color: Color(0xFF8E24AA),
  ),
  PlaceTagDefinition(
    key: 'favorite',
    label: 'Favorite',
    icon: Icons.star_rounded,
    color: Color(0xFFFFB300),
  ),
];

String normalizeTagText(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ');
}

bool isCustomTagKey(String key) {
  return key.startsWith(customTagPrefix);
}

String buildCustomTagKey(String label) {
  return '$customTagPrefix${normalizeTagText(label)}';
}

String customTagLabel(String key) {
  if (!isCustomTagKey(key)) return key;
  return key.substring(customTagPrefix.length).trim();
}

PlaceTagDefinition tagDefinitionFromKey(String key) {
  for (final tag in availableTags) {
    if (tag.key == key) {
      return tag;
    }
  }

  if (isCustomTagKey(key)) {
    return PlaceTagDefinition(
      key: key,
      label: customTagLabel(key),
      icon: Icons.sell_rounded,
      color: const Color(0xFF546E7A),
    );
  }

  return PlaceTagDefinition(
    key: key,
    label: key,
    icon: Icons.label_rounded,
    color: const Color(0xFF90A4AE),
  );
}

/// Backward-compatible helper for old files like detail.dart/history_card.dart.
/// Those files still call findTagByKey(key), so keep this method.
PlaceTagDefinition? findTagByKey(String key) {
  return tagDefinitionFromKey(key);
}