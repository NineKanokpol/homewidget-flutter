import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationManager{

  static Future<void> showFullScreenNotification(String title, String body,FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'full_screen_channel_id',     // must be unique ID
      'Full Screen Notifications',  // channel name
      channelDescription: 'This channel is used for urgent notifications that turn screen on.',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      enableVibration: true
      // You can also set additional flags like ongoing: true if needed.
    );

    NotificationDetails notificationDetails =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,          // Notification ID
      title,      // Notification title
      body,       // Notification body
      notificationDetails,
      payload: 'alarm',  // Optional payload
    );
  }
}