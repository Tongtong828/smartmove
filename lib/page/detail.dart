import 'package:flutter/material.dart';

import '../model/route_point.dart';
import '../model/sport_session.dart';
import '../model/sport_type.dart';

class DetailPage extends StatelessWidget {
  final SportSession session;

  const DetailPage({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 260,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(24),
              ),
              child: CustomPaint(
                painter: _SessionRoutePainter(points: session.points),
                child: const Center(
                  child: Text(
                    'Route Preview',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _item('Sport', session.type.label),
                    _item('Date', session.dateTimeLabel),
                    _item('Distance', '${session.distanceKm.toStringAsFixed(2)} km'),
                    _item('Duration', session.durationLabel),
                    _item('Pace / Speed', session.averagePace),
                    _item('Comfort Score', session.comfortScore.toString()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(title),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SessionRoutePainter extends CustomPainter {
  final List<RoutePoint> points;

  const _SessionRoutePainter({
    required this.points,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final gridPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final minLat = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final maxLat = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    final minLng = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final maxLng = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

    double toX(double lng) {
      if (maxLng == minLng) return size.width * 0.5;
      return 24 + ((lng - minLng) / (maxLng - minLng)) * (size.width - 48);
    }

    double toY(double lat) {
      if (maxLat == minLat) return size.height * 0.5;
      return size.height - 24 - ((lat - minLat) / (maxLat - minLat)) * (size.height - 48);
    }

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      final segmentPaint = Paint()
        ..color = _colorForComfort(current.comfortLevel)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(toX(current.longitude), toY(current.latitude)),
        Offset(toX(next.longitude), toY(next.latitude)),
        segmentPaint,
      );
    }

    final endPoint = points.last;
    final endPaint = Paint()..color = _colorForComfort(endPoint.comfortLevel);
    canvas.drawCircle(
      Offset(toX(endPoint.longitude), toY(endPoint.latitude)),
      7,
      endPaint,
    );
  }

  Color _colorForComfort(double comfort) {
    if (comfort >= 0.8) return Colors.green;
    if (comfort >= 0.6) return Colors.orange;
    return Colors.red;
  }

  @override
  bool shouldRepaint(covariant _SessionRoutePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}