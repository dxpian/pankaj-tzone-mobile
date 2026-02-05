import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/logger_alert.dart';
import '../models/app_features.dart';
import '../services/history_service.dart';
// 🟢 CHANGED: Import the new screen instead of the dialog
import 'logger_settings_screen.dart'; 

class LoggerGraphScreen extends StatefulWidget {
  final LoggerAlert logger;
  final UserProfile user; 

  const LoggerGraphScreen({
    super.key, 
    required this.logger, 
    required this.user 
  });

  @override
  State<LoggerGraphScreen> createState() => _LoggerGraphScreenState();
}

class _LoggerGraphScreenState extends State<LoggerGraphScreen> {
  bool _isLoading = true;
  List<FlSpot> _spots = [];
  
  // Alert Thresholds
  double _minTempLimit = 2.0; 
  double _maxTempLimit = 8.0;
  bool _enableTempAlert = true;
  
  // Battery Thresholds
  double _batteryMinLimit = 20.0;
  bool _enableBattAlert = false;

  // Display Preferences
  late bool _showAmbient;
  late bool _showHumidity;
  late bool _showLight;
  late bool _showVibration;
  late bool _showLocation;

  @override
  void initState() {
    super.initState();
    _showAmbient = widget.logger.showAmbient;
    _showHumidity = widget.logger.showHumidity;
    _showLight = widget.logger.showLight;
    _showVibration = widget.logger.showVibration;
    _showLocation = widget.logger.showLocation;
    _fetchGraphData();
  }

  Future<void> _fetchGraphData() async {
    final prefs = await SharedPreferences.getInstance();
    final String serial = widget.logger.serial;
    
    if (mounted) {
      setState(() {
        // Load Temp Settings
        _minTempLimit = prefs.getDouble('alert_min_$serial') ?? 2.0;
        _maxTempLimit = prefs.getDouble('alert_max_$serial') ?? 8.0;
        _enableTempAlert = prefs.getBool('alert_enabled_$serial') ?? false;
        
        // Load Battery Settings
        _batteryMinLimit = prefs.getDouble('batt_min_$serial') ?? 20.0;
        _enableBattAlert = prefs.getBool('batt_enabled_$serial') ?? false;
        
        // Load Display Preferences
        _showAmbient = prefs.getBool('show_ambient_$serial') ?? widget.logger.showAmbient;
        _showHumidity = prefs.getBool('show_humidity_$serial') ?? widget.logger.showHumidity;
        _showLight = prefs.getBool('show_light_$serial') ?? widget.logger.showLight;
        _showVibration = prefs.getBool('show_vibration_$serial') ?? widget.logger.showVibration;
        _showLocation = prefs.getBool('show_location_$serial') ?? widget.logger.showLocation;
      });
    }

    final historyService = HistoryService(widget.user.token);
    final history = await historyService.getTemperatureHistory(widget.logger.serial);

    if (mounted) {
      setState(() {
        _spots = [];
        for (var entry in history) {
          double val = 0.0;
          bool hasVal = false;

          if (widget.logger.isProbeActive) {
            if (entry['tempexternal'] != null) {
              val = (entry['tempexternal'] as num).toDouble();
              hasVal = true;
            }
          }
          if (!hasVal) {
             if (entry['temperature'] != null) {
              val = (entry['temperature'] as num).toDouble();
              hasVal = true;
            } else if (entry['temp'] != null) {
              val = (entry['temp'] as num).toDouble();
              hasVal = true;
            }
          }

          if (hasVal) {
            double timestamp = 0;
            if (entry['servertime'] != null) {
              try {
                String rawTime = entry['servertime'].toString().replaceAll('/', '-'); 
                DateTime dt = DateTime.parse(rawTime);
                timestamp = dt.millisecondsSinceEpoch.toDouble();
              } catch (e) {
                print("Date Parse Error: $e");
              }
            }
            if (timestamp > 0) {
              _spots.add(FlSpot(timestamp, val));
            }
          }
        }
        _spots.sort((a, b) => a.x.compareTo(b.x));
        _isLoading = false;
      });
    }
  }

  // 🟢 CHANGED: Now navigates to a new page instead of opening a dialog
  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggerSettingsScreen(logger: widget.logger),
      ),
    );

    // Refresh data when returning from settings to apply new threshold lines/colors
    _fetchGraphData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Logger ${widget.logger.serial}", style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings, 
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildInfoCards(), 
            const Divider(),
            _buildEnvironmentGrid(),
            const Divider(),
            SizedBox(
              height: 400,
              child: _isLoading
                  ? _buildSkeletonGraph()
                  : _spots.isEmpty
                      ? const Center(child: Text("No Data Available"))
                      : _buildGraph(), 
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraph() {
    return Padding(
      padding: const EdgeInsets.only(right: 20, top: 20, bottom: 20, left: 10),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 2000), 
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          int limit = (_spots.length * value).toInt();
          List<FlSpot> animatedSpots = _spots.sublist(0, limit);
          if (animatedSpots.isEmpty) return Container();

          return LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                      final timeStr = "${date.hour}:${date.minute.toString().padLeft(2,'0')}";
                      return LineTooltipItem(
                        "$timeStr \n${spot.y.toStringAsFixed(1)}°C",
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
                handleBuiltInTouches: true,
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1, 
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 14400000, 
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      final text = "${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}";
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(text, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: _maxTempLimit,
                    color: Colors.red.withOpacity(0.8),
                    strokeWidth: 2,
                    dashArray: [5, 5], 
                    label: HorizontalLineLabel(show: true, labelResolver: (line) => "Max ${_maxTempLimit}°C", style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  HorizontalLine(
                    y: _minTempLimit,
                    color: Colors.blue.withOpacity(0.8),
                    strokeWidth: 2,
                    dashArray: [5, 5], 
                    label: HorizontalLineLabel(show: true, labelResolver: (line) => "Min ${_minTempLimit}°C", style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

              lineBarsData: [
                LineChartBarData(
                  spots: animatedSpots,
                  isCurved: true,
                  color: Colors.blue.shade700,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.3),
                        Colors.blue.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonGraph() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 50, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text("Loading Data...", style: TextStyle(color: Colors.grey.shade400)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    Color tempColor = Colors.green;
    IconData tempIcon = widget.logger.isProbeActive ? Icons.thermostat : Icons.cloud;
    
    bool isTempViolation = false;
    if (_enableTempAlert) {
      if (widget.logger.temperature > _maxTempLimit || widget.logger.temperature < _minTempLimit) {
        isTempViolation = true;
      }
    }
    if (isTempViolation) {
      tempColor = Colors.red;
      tempIcon = Icons.warning_amber_rounded;
    }

    Color battColor = Colors.green;
    IconData battIcon = Icons.battery_full;

    if (widget.logger.battery < _batteryMinLimit) {
      battColor = Colors.red;
      battIcon = Icons.battery_alert;
    }

    String mainLabel = widget.logger.isProbeActive ? "Probe Temp" : "Ambient Temp";

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _infoCard(mainLabel, "${widget.logger.temperature}°C", tempIcon, tempColor),
          
          if (widget.logger.isProbeActive && _showAmbient) ...[
            const SizedBox(width: 10),
            _infoCard("Ambient (Sec)", "${widget.logger.ambientTemp}°C", Icons.cloud_outlined, Colors.blueGrey),
          ],
          
          const SizedBox(width: 10),
          _infoCard("Battery", "${widget.logger.battery.toInt()}%", battIcon, battColor),
        ],
      ),
    );
  }

  Widget _buildEnvironmentGrid() {
    List<Widget> cards = [];

    if (_showHumidity) {
      cards.add(_envCard("Humidity", "${widget.logger.humidity}%", Icons.water_drop, Colors.blueAccent));
    }
    if (_showLight) {
      cards.add(_envCard("Light", "${widget.logger.light.toInt()} Lux", Icons.wb_sunny, Colors.orangeAccent));
    }
    if (_showVibration) {
      cards.add(_envCard("Vibration", "${widget.logger.vibration.toInt()}", Icons.vibration, Colors.purple));
    }
    if (_showLocation) {
      cards.add(_envCard("Location", widget.logger.city, Icons.location_city, Colors.grey));
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    List<Widget> rows = [];
    for (int i = 0; i < cards.length; i += 2) {
      rows.add(
        Row(
          children: [
            cards[i],
            const SizedBox(width: 10),
            if (i + 1 < cards.length) cards[i + 1] else const Spacer(),
          ],
        )
      );
      if (i + 2 < cards.length) rows.add(const SizedBox(height: 10));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Environment Status", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _envCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}