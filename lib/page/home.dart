import 'package:flutter/material.dart';

import '../model/route_point.dart';
import '../model/sport_session.dart';
import '../model/sport_type.dart';
import '../widget/select_list.dart';
import '../widget/stats_panel.dart';
import 'summary.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isTracking = false;
  SportType? selectedType;

  String durationText = '00:00:00';
  String distanceText = '0.0 km';
  String paceText = '--';
  int comfortScore = 0;

  void _showSelectSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SelectListSheet(
          onSelected: _startTracking,
        );
      },
    );
  }

  void _startTracking(SportType type) {
    setState(() {
      selectedType = type;
      isTracking = true;

      switch (type) {
        case SportType.walking:
          durationText = '00:28:16';
          distanceText = '2.7 km';
          paceText = '10\'28"/km';
          comfortScore = 74;
          break;
        case SportType.running:
          durationText = '00:24:32';
          distanceText = '4.6 km';
          paceText = '05\'20"/km';
          comfortScore = 86;
          break;
        case SportType.cycling:
          durationText = '00:36:48';
          distanceText = '14.2 km';
          paceText = '23.1 km/h';
          comfortScore = 68;
          break;
      }
    });
  }

  Future<void> _finishTracking() async {
    if (selectedType == null) return;

    final now = DateTime.now();
    final duration = _parseDuration(durationText);

    final session = SportSession(
      id: now.millisecondsSinceEpoch.toString(),
      type: selectedType!,
      startedAt: now.subtract(duration),
      endedAt: now,
      distanceKm: _parseDistance(distanceText),
      averagePace: paceText,
      comfortScore: comfortScore,
      points: List.generate(
        8,
        (index) => RoutePoint(
          latitude: 51.50 + index * 0.001,
          longitude: -0.12 + index * 0.001,
          timestamp: now.subtract(Duration(minutes: 24 - index * 3)),
          comfortLevel: comfortScore / 100,
        ),
      ),
    );

    SessionStore.addSession(session);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryPage(session: session),
      ),
    );

    if (!mounted) return;

    setState(() {
      isTracking = false;
      selectedType = null;
      durationText = '00:00:00';
      distanceText = '0.0 km';
      paceText = '--';
      comfortScore = 0;
    });
  }

  double _parseDistance(String text) {
    return double.tryParse(text.split(' ').first) ?? 0;
  }

  Duration _parseDuration(String text) {
    final parts = text.split(':');
    if (parts.length != 3) return Duration.zero;

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartMove'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color(0xFFF4F7FB),
                  ),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size.infinite,
                        painter: _HomeMapPainter(
                          isTracking: isTracking,
                          comfortScore: comfortScore,
                        ),
                        child: const SizedBox.expand(),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isTracking
                                ? '${selectedType?.label ?? ''} in progress'
                                : 'Live map will appear here',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.circle, color: Colors.green, size: 12),
                              SizedBox(width: 6),
                              Text('Smooth'),
                              SizedBox(width: 12),
                              Icon(Icons.circle, color: Colors.red, size: 12),
                              SizedBox(width: 6),
                              Text('Rough'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              StatsPanel(
                isTracking: isTracking,
                sportType: selectedType,
                durationText: durationText,
                distanceText: distanceText,
                paceText: paceText,
                comfortScore: comfortScore,
              ),
              const SizedBox(height: 16),
              if (!isTracking)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _showSelectSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Start Activity'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showSelectSheet,
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Change'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _finishTracking,
                        icon: const Icon(Icons.stop),
                        label: const Text('Finish'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMapPainter extends CustomPainter {
  final bool isTracking;
  final int comfortScore;

  const _HomeMapPainter({
    required this.isTracking,
    required this.comfortScore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (!isTracking) return;

    final smoothPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final mediumPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roughPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final points = [
      Offset(size.width * 0.18, size.height * 0.78),
      Offset(size.width * 0.32, size.height * 0.62),
      Offset(size.width * 0.46, size.height * 0.56),
      Offset(size.width * 0.62, size.height * 0.40),
      Offset(size.width * 0.78, size.height * 0.25),
    ];

    canvas.drawLine(points[0], points[1], smoothPaint);
    canvas.drawLine(points[1], points[2], mediumPaint);
    canvas.drawLine(points[2], points[3], roughPaint);
    canvas.drawLine(points[3], points[4], smoothPaint);

    final dotPaint = Paint()
      ..color = comfortScore >= 80
          ? Colors.green
          : comfortScore >= 60
              ? Colors.orange
              : Colors.red;

    canvas.drawCircle(points.last, 8, dotPaint);

    final glowPaint = Paint()
      ..color = dotPaint.color.withValues(alpha: 0.25);

    canvas.drawCircle(points.last, 14, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _HomeMapPainter oldDelegate) {
    return oldDelegate.isTracking != isTracking ||
        oldDelegate.comfortScore != comfortScore;
  }
}