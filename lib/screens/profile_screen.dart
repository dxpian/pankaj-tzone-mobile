import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Profile section coming soon",
          style: TextStyle(color: AppColors.darkText, fontSize: 18),
        ),
      ),
    );
  }
}
