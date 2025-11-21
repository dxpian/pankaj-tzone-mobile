import 'dart:math';
import 'package:flutter/material.dart';
import '../models/logger_alert.dart';

class LoggerGraphScreen extends StatelessWidget {
  final LoggerAlert logger;

  const LoggerGraphScreen({
    super.key,
    required this.logger,
  });

  Color getSeverityColor(int minutes) {
    if (minutes >= 20) return Colors.red;
    if (minutes >= 10) return Colors.orange;
    return Colors.yellow.shade700;
  }

  String getSeverityLabel(int minutes) {
    if (minutes >= 20) return "High Severity";
    if (minutes >= 10) return "Medium Severity";
    return "Low Severity";
  }

  @override
  Widget build(BuildContext context) {
    final Color severityColor = getSeverityColor(logger.minutesInAlert);
    final String severityLabel = getSeverityLabel(logger.minutesInAlert);

    // Simulate 2–3 hours of data (e.g. 60 points)
    final List<Offset> points = _generateSimulatedPoints(
      baseTemp: logger.temperature,
      severityColor: severityColor,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Logger ${logger.serial}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            // TOP SUMMARY CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Logger ID",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          logger.serial,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Location",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const Text(
                          "Same as cluster (from API later)",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: severityColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning, size: 18, color: severityColor),
                        const SizedBox(width: 6),
                        Text(
                          severityLabel,
                          style: TextStyle(
                            color: severityColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // GRAPH CARD
            Expanded(
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Graph header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Last 3 hours – Temperature",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "${logger.temperature.toStringAsFixed(1)}°C now",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: severityColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Simulated data (API integration later)",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Animated graph
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CustomPaint(
                              painter: _TemperatureGraphPainter(
                                points: points,
                                severityColor: severityColor,
                                progress: value,
                              ),
                              child: Container(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // X-axis labels (simple)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("−3h",
                            style:
                                TextStyle(fontSize: 11, color: Colors.grey)),
                        Text("−2h",
                            style:
                                TextStyle(fontSize: 11, color: Colors.grey)),
                        Text("−1h",
                            style:
                                TextStyle(fontSize: 11, color: Colors.grey)),
                        Text("Now",
                            style:
                                TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // BOTTOM SUMMARY ROWS
            Row(
              children: [
                _infoTile(
                  title: "Current Temp",
                  value: "${logger.temperature.toStringAsFixed(1)}°C",
                  color: severityColor,
                ),
                const SizedBox(width: 12),
                _infoTile(
                  title: "In Alert",
                  value: "${logger.minutesInAlert} min",
                  color: severityColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _infoTile(
                  title: "Battery",
                  value: "Good",
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 12),
                _infoTile(
                  title: "Last Updated",
                  value: "Just now",
                  color: Colors.blue.shade700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // small bottom tiles
  Widget _infoTile({
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generate smooth-ish series around base temperature
  List<Offset> _generateSimulatedPoints({
    required double baseTemp,
    required Color severityColor,
  }) {
    final rand = Random();
    const int count = 60; // 60 points over ~3h
    final List<Offset> pts = [];
    final double amplitude = 0.5 + (severityColor == Colors.red
        ? 1.0
        : (severityColor == Colors.orange ? 0.7 : 0.4));

    for (int i = 0; i < count; i++) {
      final t = i / (count - 1);
      final wave = sin(t * pi * 4); // 2 cycles
      final noise = (rand.nextDouble() - 0.5) * 0.3;
      final temp = baseTemp + wave * amplitude + noise;

      pts.add(Offset(t, temp));
    }
    return pts;
  }
}

class _TemperatureGraphPainter extends CustomPainter {
  final List<Offset> points;
  final Color severityColor;
  final double progress; // 0..1 for animation

  _TemperatureGraphPainter({
    required this.points,
    required this.severityColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Map logical points (0..1, temp) to canvas coords
    final temps = points.map((e) => e.dy).toList();
    final minT = temps.reduce(min);
    final maxT = temps.reduce(max);
    final double padding = 10;

    Offset mapPoint(Offset p) {
      final x = padding + p.dx * (size.width - 2 * padding);
      final normT =
          (p.dy - minT) / ((maxT - minT).abs() < 0.001 ? 1 : (maxT - minT));
      final y =
          size.height - padding - normT * (size.height - 2 * padding);
      return Offset(x, y);
    }

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < (points.length * progress).clamp(2, points.length).toInt(); i++) {
      final p = mapPoint(points[i]);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
        fillPath.moveTo(p.dx, size.height - padding);
        fillPath.lineTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
        fillPath.lineTo(p.dx, p.dy);
      }
    }

    // Close fill to bottom
    final lastX = mapPoint(points[
            (points.length * progress).clamp(1, points.length).toInt() - 1])
        .dx;
    fillPath.lineTo(lastX, size.height - padding);
    fillPath.close();

    // Gradient under the line
    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          severityColor.withOpacity(0.35),
          severityColor.withOpacity(0.02),
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    // Line paint
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = severityColor;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TemperatureGraphPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.severityColor != severityColor ||
        oldDelegate.progress != progress;
  }
}
