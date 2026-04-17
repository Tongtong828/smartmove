import 'package:flutter/material.dart';

import '../model/sport_type.dart';

class StatsPanel extends StatelessWidget {
  final bool isTracking;
  final SportType? sportType;
  final String durationText;
  final String distanceText;
  final String paceText;
  final int comfortScore;

  const StatsPanel({
    super.key,
    required this.isTracking,
    required this.sportType,
    required this.durationText,
    required this.distanceText,
    required this.paceText,
    required this.comfortScore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  sportType?.icon ?? Icons.route,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  sportType?.label ?? 'No activity selected',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isTracking ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isTracking ? 'Tracking' : 'Idle',
                    style: TextStyle(
                      color: isTracking ? Colors.green.shade700 : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Time',
                    value: durationText,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Distance',
                    value: distanceText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: sportType?.paceLabel ?? 'Pace',
                    value: paceText,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Comfort',
                    value: '$comfortScore / 100',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}