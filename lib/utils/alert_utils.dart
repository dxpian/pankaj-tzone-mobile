import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';

Color getAlertColor(int minutes) {
  if (minutes >= 20) return Colors.red;
  if (minutes >= 10) return Colors.orange;
  return Colors.yellow.shade700;
}

void playAlertSound() {
  FlutterRingtonePlayer.playNotification(
    looping: false,
    volume: 0.8,
    asAlarm: false,
  );
}

Future<void> vibrateIfSevere(int minutes) async {
  if (minutes >= 20) {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500);
    }
  }
}
