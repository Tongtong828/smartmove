import 'package:flutter/foundation.dart';

import 'route_point.dart';
import 'sport_type.dart';

class SportSession {
  final String id;
  final SportType type;
  final DateTime startedAt;
  final DateTime endedAt;
  final double distanceKm;
  final String averagePace;
  final int comfortScore;
  final List<RoutePoint> points;

  const SportSession({
    required this.id,
    required this.type,
    required this.startedAt,
    required this.endedAt,
    required this.distanceKm,
    required this.averagePace,
    required this.comfortScore,
    required this.points,
  });

  Duration get duration => endedAt.difference(startedAt);

  int get durationSeconds => duration.inSeconds;

  String get dateTimeLabel {
    return '${startedAt.year.toString().padLeft(4, '0')}-'
        '${_two(startedAt.month)}-'
        '${_two(startedAt.day)} '
        '${_two(startedAt.hour)}:${_two(startedAt.minute)}';
  }

  String get durationLabel {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${_two(hours)}:${_two(minutes)}:${_two(seconds)}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class SessionStore {
  SessionStore._();

  static final ValueNotifier<List<SportSession>> sessions =
      ValueNotifier<List<SportSession>>(_seedSessions());

  static void addSession(SportSession session) {
    sessions.value = [session, ...sessions.value];
  }

  static List<SportSession> _seedSessions() {
    final now = DateTime.now();

    return [
      SportSession(
        id: 'seed-1',
        type: SportType.running,
        startedAt: now.subtract(const Duration(days: 1, hours: 2)),
        endedAt: now.subtract(const Duration(days: 1, hours: 1, minutes: 32)),
        distanceKm: 5.2,
        averagePace: '05\'38"/km',
        comfortScore: 84,
        points: _demoPoints(now.subtract(const Duration(days: 1)), 0.84),
      ),
      SportSession(
        id: 'seed-2',
        type: SportType.walking,
        startedAt: now.subtract(const Duration(days: 3, hours: 5)),
        endedAt: now.subtract(const Duration(days: 3, hours: 4, minutes: 18)),
        distanceKm: 3.1,
        averagePace: '10\'56"/km',
        comfortScore: 73,
        points: _demoPoints(now.subtract(const Duration(days: 3)), 0.73),
      ),
      SportSession(
        id: 'seed-3',
        type: SportType.cycling,
        startedAt: now.subtract(const Duration(days: 6, hours: 1)),
        endedAt: now.subtract(const Duration(days: 6, minutes: 20)),
        distanceKm: 12.8,
        averagePace: '23.4 km/h',
        comfortScore: 67,
        points: _demoPoints(now.subtract(const Duration(days: 6)), 0.67),
      ),
    ];
  }

  static List<RoutePoint> _demoPoints(DateTime base, double comfort) {
    return List.generate(
      8,
      (index) => RoutePoint(
        latitude: 51.50 + index * 0.001,
        longitude: -0.12 + index * 0.001,
        timestamp: base.add(Duration(minutes: index * 4)),
        comfortLevel: comfort,
      ),
    );
  }
}