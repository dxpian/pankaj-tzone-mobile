import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/logger_alert.dart';
import '../models/app_features.dart';
import '../services/history_service.dart'; 

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

  @override
  void initState() {
    super.initState();
    _fetchGraphData();
  }

  Future<void> _fetchGraphData() async {
    final historyService = HistoryService(widget.user.token);
    final history = await historyService.getTemperatureHistory(widget.logger.serial);

    if (mounted) {
      setState(() {
        _spots = [];
        
        for (var entry in history) {
          // 🟢 GRAPH LOGIC: Prefer Probe (tempexternal) to match Alerts
          double val = 0.0;
          if (entry['tempexternal'] != null) {
            val = (entry['tempexternal'] as num).toDouble();
          } else if (entry['temperature'] != null) {
            val = (entry['temperature'] as num).toDouble();
          } else if (entry['temp'] != null) {
            val = (entry['temp'] as num).toDouble();
          }

          // Parse Time
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

        _spots.sort((a, b) => a.x.compareTo(b.x));
        _isLoading = false;
      });
    }
  }

  void _showSettingsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final String serial = widget.logger.serial;
    
    bool isEnabled = prefs.getBool('alert_enabled_$serial') ?? false;
    double minTemp = prefs.getDouble('alert_min_$serial') ?? 2.0;
    double maxTemp = prefs.getDouble('alert_max_$serial') ?? 8.0;

    final minController = TextEditingController(text: minTemp.toString());
    final maxController = TextEditingController(text: maxTemp.toString());

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        bool localEnabled = isEnabled;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Configure Alerts"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text("Enable Probe Alert"),
                    value: localEnabled,
                    activeColor: Colors.red,
                    onChanged: (v) => setDialogState(() => localEnabled = v),
                  ),
                  const SizedBox(height: 10),
                  const Text("Alerts trigger on Probe Temp only.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Min Temperature (°C)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Max Temperature (°C)", border: OutlineInputBorder()),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
                  onPressed: () async {
                    await prefs.setBool('alert_enabled_$serial', localEnabled);
                    await prefs.setDouble('alert_min_$serial', double.tryParse(minController.text) ?? 2.0);
                    await prefs.setDouble('alert_max_$serial', double.tryParse(maxController.text) ?? 8.0);
                    if (context.mounted) Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Alert settings saved locally.")),
                    );
                  },
                  child: const Text("Save"),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logger ${widget.logger.serial}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
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
                  ? const Center(child: CircularProgressIndicator())
                  : _spots.isEmpty
                      ? const Center(child: Text("No Data Available"))
                      : Padding(
                          padding: const EdgeInsets.only(right: 20, top: 20, bottom: 20, left: 10),
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: true),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    // 🟢 CHANGED: Set Interval to 4 Hours (in milliseconds)
                                    // 4 * 60 * 60 * 1000 = 14,400,000
                                    interval: 14400000, 
                                    getTitlesWidget: (value, meta) {
                                      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                      final text = "${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}";
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(text, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _spots,
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // 🟢 KEEPING PROBE & AMBIENT VISIBLE
          _infoCard("Probe Temp", "${widget.logger.temperature}°C", Icons.thermostat, Colors.redAccent),
          const SizedBox(width: 10),
          _infoCard("Ambient Temp", "${widget.logger.ambientTemp}°C", Icons.cloud, Colors.blueGrey),
          const SizedBox(width: 10),
          _infoCard("Battery", "${widget.logger.battery.toInt()}%", Icons.battery_full, Colors.green),
        ],
      ),
    );
  }

  Widget _buildEnvironmentGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Environment Status", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              _envCard("Humidity", "${widget.logger.humidity}%", Icons.water_drop, Colors.blueAccent),
              const SizedBox(width: 10),
              _envCard("Light", "${widget.logger.light.toInt()} Lux", Icons.wb_sunny, Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _envCard("Vibration", "${widget.logger.vibration.toInt()}", Icons.vibration, Colors.purple),
              const SizedBox(width: 10),
              _envCard("Location", widget.logger.city, Icons.location_city, Colors.grey),
            ],
          ),
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