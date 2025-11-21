import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class GraphScreen extends StatelessWidget {
  const GraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text('Graph', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(child: Text('Graph screen placeholder')),
    );
  }
}
