import 'package:flutter/material.dart';

class CheckInTag {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const CheckInTag({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const List<CheckInTag> availableTags = [
  CheckInTag(
    key: 'travel',
    label: 'Travel',
    icon: Icons.flight_takeoff_rounded,
    color: Color(0xFF2563EB),
  ),
  CheckInTag(
    key: 'walk',
    label: 'Walk',
    icon: Icons.directions_walk_rounded,
    color: Color(0xFF16A34A),
  ),
  CheckInTag(
    key: 'food',
    label: 'Food',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFEA580C),
  ),
  CheckInTag(
    key: 'cafe',
    label: 'Cafe',
    icon: Icons.local_cafe_rounded,
    color: Color(0xFF8B5CF6),
  ),
  CheckInTag(
    key: 'museum',
    label: 'Museum',
    icon: Icons.museum_rounded,
    color: Color(0xFFDC2626),
  ),
  CheckInTag(
    key: 'park',
    label: 'Park',
    icon: Icons.park_rounded,
    color: Color(0xFF059669),
  ),
  CheckInTag(
    key: 'shopping',
    label: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFFDB2777),
  ),
  CheckInTag(
    key: 'friends',
    label: 'Friends',
    icon: Icons.groups_rounded,
    color: Color(0xFF0EA5E9),
  ),
];

CheckInTag? findTagByKey(String key) {
  try {
    return availableTags.firstWhere((tag) => tag.key == key);
  } catch (_) {
    return null;
  }
}