import 'dart:async';
import 'dart:io';

import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:home_widget/home_widget.dart';
import 'package:homewidget/api/model/pray_time_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma("vm:entry-point")
class CountdownManager {
  static Timer? _timer;
  static bool _isUpdating = false; // Flag to prevent overlapping updates

  /// Start the countdown timer (only one timer will run).
  static void startCountdown() {
    if (_timer != null) return; // Prevent multiple timers from running.
    print("Starting countdown timer.");
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isUpdating) {
        print("Update already in progress; skipping tick.");
        return;
      }
      _isUpdating = true;
      _updateCountdownLogic().whenComplete(() {
        _isUpdating = false;
      });
    });
  }

  /// Stop the countdown timer.
  static void stopCountdown() {
    _timer?.cancel();
    _timer = null;
    print("Countdown timer stopped.");
  }

  /// The main countdown logic.
  ///
  /// Retrieves prayer times from SharedPreferences, finds the next upcoming prayer,
  /// and if that prayer time is within 5 minutes, formats a countdown string:
  /// - If remaining time ≥ 60 seconds: displays minutes (e.g. "4 นาที").
  /// - If remaining time < 60 seconds: displays seconds (e.g. "45 วินาที").
  /// Otherwise, if the next prayer is more than 5 minutes away, a default message is shown.
  static Future<void> _updateCountdownLogic() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Retrieve prayer times from SharedPreferences.
      final String time1 = prefs.getString("time1") ?? "";
      final String time2 = prefs.getString("time2") ?? "";
      final String time3 = prefs.getString("time3") ?? "";
      final String time4 = prefs.getString("time4") ?? "";
      final String time5 = prefs.getString("time5") ?? "";
      final String time6 = prefs.getString("time6") ?? "";

      final List<String> prayerTimesStr = [time1, time2, time3, time4, time5, time6];

      final DateTime now = DateTime.now();
      List<DateTime> prayerDateTimes = [];

      // Parse each prayer time (assumes format "HH:mm")
      for (final timeStr in prayerTimesStr) {
        if (timeStr.isNotEmpty) {
          final parts = timeStr.split(":");
          final int hour = int.tryParse(parts[0]) ?? 0;
          final int minute = int.tryParse(parts[1]) ?? 0;
          DateTime prayerTime = DateTime(now.year, now.month, now.day, hour, minute);
          // If the prayer time has already passed today, assume it’s for tomorrow.
          if (prayerTime.isBefore(now)) {
            prayerTime = prayerTime.add(const Duration(days: 1));
          }
          prayerDateTimes.add(prayerTime);
        }
      }

      // If no prayer times are available, use a default message.
      String displayCountdown;
      if (prayerDateTimes.isEmpty) {
        displayCountdown = "No prayer times";
      } else {
        // Sort to get the next upcoming prayer time.
        prayerDateTimes.sort((a, b) => a.compareTo(b));
        final DateTime nextPrayer = prayerDateTimes.first;
        final int diffSeconds = nextPrayer.difference(now).inSeconds;
        print("Next prayer at: $nextPrayer, seconds remaining: $diffSeconds");

        // Only trigger countdown display if within 5 minutes (300 seconds)
        if (diffSeconds <= 300) {
          // Format output: if ≥ 60 seconds, display minutes; otherwise, display seconds.
          if (diffSeconds >= 60) {
            int minutesRemaining = diffSeconds ~/ 60;
            displayCountdown = "$minutesRemaining นาที";
          } else {
            displayCountdown = "$diffSeconds วินาที";
          }

          // When the countdown reaches 0, you can play the alert sound.
          if (diffSeconds <= 0) {
            print("Prayer time reached. Playing alert sound.");
            FlutterRingtonePlayer().play(
              fromAsset: 'assets/audio/alarm_sound.mp3',
              looping: false,
              volume: 1.0,
              asAlarm: true,
            );
            // Optionally: stop countdown or wait for new prayer time.
            displayCountdown = "0 วินาที";
            // You might decide to stop the timer until the next prayer update.
          }
        } else {
          // When more than 5 minutes remain, show a default text or the full time.
          // For example, display the scheduled prayer time itself:
          displayCountdown = "Scheduled: ${nextPrayer.hour.toString().padLeft(2, '0')}:${nextPrayer.minute.toString().padLeft(2, '0')}";
        }
      }

      // Save the formatted countdown string to SharedPreferences (or directly update the widget).
      await HomeWidget.saveWidgetData<String>("timer_value", displayCountdown);
      print("Countdown display saved: $displayCountdown");

      // Optionally, also save the raw value (if needed).
      // await prefs.setInt("timer_value", diffSeconds);

      // Update the widget.
      try {
        if (Platform.isAndroid) {
          await HomeWidget.updateWidget(
            qualifiedAndroidName: 'com.example.homewidget.glance.HomeWidgetReceiver',
            androidName: 'HomeWidgetExampleProvider',
          );
        } else {
          await HomeWidget.updateWidget(
            androidName: 'HomeWidgetExampleProvider',
            iOSName: 'HomeWidgetExample',
          );
        }
        print("Widget updated successfully.");
      } catch (e) {
        print("Error updating widget: $e");
      }
    } catch (e, stackTrace) {
      print("Error in updateCountdown: $e");
      print(stackTrace);
    }
  }
}