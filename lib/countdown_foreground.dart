import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_foreground_task/task_handler.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CountdownTaskHandler extends TaskHandler {
  int _start = 400; // For example, 400 seconds countdown

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print("Foreground service started at $timestamp");
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print("Foreground service destroyed at $timestamp");
  }

  @override
  void onButtonPressed(String id) {
    // Handle notification button taps if needed.
  }

  @override
  void onNotificationPressed() {
    // Handle notification tap events if necessary.
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    try {
      // Get shared preferences (or you could use HomeWidget.saveWidgetData as appropriate).
      final prefs = await SharedPreferences.getInstance();

      // Retrieve prayer times from SharedPreferences.
      final String time1 = prefs.getString("time1") ?? "";
      final String time2 = prefs.getString("time2") ?? "";
      final String time3 = prefs.getString("time3") ?? "";
      final String time4 = prefs.getString("time4") ?? "";
      final String time5 = prefs.getString("time5") ?? "";
      final String time6 = prefs.getString("time6") ?? "";

      final List<String> prayerTimesStr = [
        time1,
        time2,
        time3,
        time4,
        "23:17",
        time6
      ];

      final DateTime now = DateTime.now();
      List<DateTime> prayerDateTimes = [];

      // Parse the prayer times (assuming they are in "HH:mm" format).
      for (final timeStr in prayerTimesStr) {
        if (timeStr.isNotEmpty) {
          final parts = timeStr.split(":");
          final int hour = int.tryParse(parts[0]) ?? 0;
          final int minute = int.tryParse(parts[1]) ?? 0;
          DateTime prayerTime =
              DateTime(now.year, now.month, now.day, hour, minute);
          // If this time has already passed today, assume it’s for tomorrow.
          if (prayerTime.isBefore(now)) {
            prayerTime = prayerTime.add(const Duration(days: 1));
          }
          prayerDateTimes.add(prayerTime);
        }
      }

      String displayCountdown;

      if (prayerDateTimes.isEmpty) {
        displayCountdown = "ไม่มีเวลาละหมาดที่กำหนด";
      } else {
        // Sort the list to find the next upcoming prayer.
        prayerDateTimes.sort((a, b) => a.compareTo(b));
        final DateTime nextPrayer = prayerDateTimes.first;
        final int diffSeconds = nextPrayer.difference(now).inSeconds;
        print("Next prayer at: $nextPrayer, seconds remaining: $diffSeconds");

        if (diffSeconds <= 300) {
          // When within 5 minutes (300 seconds)
          if (diffSeconds >= 60) {
            int minutesRemaining = diffSeconds ~/ 60;
            displayCountdown = "ถึงเวลาละหมาดในอีก: $minutesRemaining นาที";
          } else {
            displayCountdown = "ถึงเวลาละหมาดในอีก: $diffSeconds วินาที";
          }

          // When time is up, play an alert sound.
          if (diffSeconds <= 0) {
            print("Prayer time reached. Playing alert sound.");
            FlutterRingtonePlayer().play(
              fromAsset: 'assets/audio/alarm_sound.mp3',
              looping: false,
              volume: 1.0,
              asAlarm: true,
            );
            displayCountdown = "ถึงเวลาละหมาดในอีก: 0 วินาที";
          }
        } else {
          // More than 5 minutes remain: show scheduled prayer time.
          displayCountdown =
              "เวลาถัดไปในการละหมาด: ${nextPrayer.hour.toString().padLeft(2, '0')}:${nextPrayer.minute.toString().padLeft(2, '0')}";
        }
      }

      // Save the formatted countdown string using HomeWidget.
      await HomeWidget.saveWidgetData<String>("timer_value", displayCountdown);
      await HomeWidget.updateWidget(
        qualifiedAndroidName:
            'com.example.homewidget.glance.HomeWidgetReceiver',
        androidName: 'HomeWidgetExampleProvider',
      );

      print("Countdown display updated: $displayCountdown");
    } catch (e, stackTrace) {
      print("Error in onRepeatEvent: $e");
      print(stackTrace);
    }
  }
}
