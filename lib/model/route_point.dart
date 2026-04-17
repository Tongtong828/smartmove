class RoutePoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double comfortLevel;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.comfortLevel,
  });
}