import 'package:flutter/material.dart';

import '../model/sport_session.dart';
import '../model/sport_type.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  double _sumDistance(
    List<SportSession> sessions,
    DateTime from,
    SportType type,
  ) {
    return sessions
        .where((session) => session.type == type && session.startedAt.isAfter(from))
        .fold(0.0, (sum, session) => sum + session.distanceKm);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<SportSession>>(
          valueListenable: SessionStore.sessions,
          builder: (context, sessions, child) {
            final now = DateTime.now();
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            final monthStart = DateTime(now.year, now.month, 1);
            final yearStart = DateTime(now.year, 1, 1);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          child: Icon(Icons.person),
                        ),
                        SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tong',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text('SmartMove User'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _RangeCard(
                  title: 'This Week',
                  walkingKm: _sumDistance(sessions, weekStart, SportType.walking),
                  runningKm: _sumDistance(sessions, weekStart, SportType.running),
                  cyclingKm: _sumDistance(sessions, weekStart, SportType.cycling),
                ),
                const SizedBox(height: 12),
                _RangeCard(
                  title: 'This Month',
                  walkingKm: _sumDistance(sessions, monthStart, SportType.walking),
                  runningKm: _sumDistance(sessions, monthStart, SportType.running),
                  cyclingKm: _sumDistance(sessions, monthStart, SportType.cycling),
                ),
                const SizedBox(height: 12),
                _RangeCard(
                  title: 'This Year',
                  walkingKm: _sumDistance(sessions, yearStart, SportType.walking),
                  runningKm: _sumDistance(sessions, yearStart, SportType.running),
                  cyclingKm: _sumDistance(sessions, yearStart, SportType.cycling),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RangeCard extends StatelessWidget {
  final String title;
  final double walkingKm;
  final double runningKm;
  final double cyclingKm;

  const _RangeCard({
    required this.title,
    required this.walkingKm,
    required this.runningKm,
    required this.cyclingKm,
  });

  @override
  Widget build(BuildContext context) {
    final total = walkingKm + runningKm + cyclingKm;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title • ${total.toStringAsFixed(1)} km',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            _DistanceRow(label: 'Walking', value: walkingKm),
            const SizedBox(height: 10),
            _DistanceRow(label: 'Running', value: runningKm),
            const SizedBox(height: 10),
            _DistanceRow(label: 'Cycling', value: cyclingKm),
          ],
        ),
      ),
    );
  }
}

class _DistanceRow extends StatelessWidget {
  final String label;
  final double value;

  const _DistanceRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label),
        const Spacer(),
        Text(
          '${value.toStringAsFixed(1)} km',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}