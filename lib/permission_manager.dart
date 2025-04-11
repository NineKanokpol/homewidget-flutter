import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_foreground_task/models/notification_permission.dart';

class PermissionManager {
  static Future<void> requestPermissions() async {
    try {
      // Check and request notification permission (especially needed on Android 13+)
      final NotificationPermission notificationPermission =
      await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
    } catch (e) {
      // Handle if the permission dialog was closed or the request was cancelled
      print("Notification permission error: $e");
      // Optionally, inform the user that notification permission is required.
    }

    if (Platform.isAndroid) {
      try {
        // Request to ignore battery optimizations.
        if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
          await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        }
      } catch (e) {
        print("Battery optimization error: $e");
      }
      try {
        // Check for exact alarm scheduling permission and prompt the user if needed.
        if (!await FlutterForegroundTask.canScheduleExactAlarms) {
          await FlutterForegroundTask.openAlarmsAndRemindersSettings();
        }
      } catch (e) {
        print("Exact alarms permission error: $e");
      }
    }
  }
}
