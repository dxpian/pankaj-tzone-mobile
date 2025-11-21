import 'package:flutter/material.dart';
import '../models/logger_alert.dart';
import 'logger_graph_screen.dart';

class ClusterDetailsPage extends StatelessWidget {
  final String clusterName;
  final List<LoggerAlert> alerts;

  const ClusterDetailsPage({
    super.key,
    required this.clusterName,
    required this.alerts,
  });

  Color getColor(int min) {
    if (min >= 20) return Colors.red;
    if (min >= 10) return Colors.orange;
    return Colors.yellow.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...alerts]
      ..sort((a, b) => b.minutesInAlert.compareTo(a.minutesInAlert));

    return Scaffold(
      appBar: AppBar(
        title: Text(clusterName),
        centerTitle: true,
      ),

      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: sorted.length,
        itemBuilder: (context, i) {
          final a = sorted[i];
          final color = getColor(a.minutesInAlert);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 450),
                  pageBuilder: (_, __, ___) =>
                      LoggerGraphScreen(logger: a),
                  transitionsBuilder: (_, anim, __, child) {
                    return SlideTransition(
                      position: Tween(
                        begin: const Offset(0.25, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    );
                  },
                ),
              );
            },

            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(color: color, width: 6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.serial,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${a.temperature.toStringAsFixed(2)}°C",
                        style: TextStyle(
                          color: color,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${a.minutesInAlert} min",
                        style: TextStyle(
                          color: color,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
