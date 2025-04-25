import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_widget/home_widget.dart';
import 'package:homewidget/api/api_http.dart';
import 'package:homewidget/api/res/prayer_time_response.dart';
import 'package:homewidget/countdown_manager.dart';
import 'package:homewidget/permission_manager.dart';
import 'package:homewidget/services/alram_service.dart';
import 'package:homewidget/services/full_screen_custom.dart';
import 'package:homewidget/services/live_activity_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'api/model/pray_time_model.dart';
import 'countdown_foreground.dart';

/// Used for Background Updates using Workmanager Plugin
@pragma("vm:entry-point")
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    final prefs = await SharedPreferences.getInstance();
    if (taskName == "updatePrayerTimes") {
      if (Platform.isAndroid) {
        try {
          await Geolocator.getCurrentPosition().then((value) async {
            await ApiHttp()
                .fetchPrayerTimes(value.latitude, value.longitude, 7)
                .then((value) async {
              await prefs.setString("time1", value.time1);
              await prefs.setString("time2", value.time2);
              await prefs.setString("time3", value.time3);
              await prefs.setString("time4", value.time4);
              await prefs.setString("time5", value.time5);
              await prefs.setString("time6", value.time6);
              Future.wait([
                HomeWidget.saveWidgetData<String>('fajrTime', "${value.time1}"),
                HomeWidget.saveWidgetData<String>(
                    'sunriseTime', "${value.time2}"),
                HomeWidget.saveWidgetData<String>(
                    'dhuhrTime', "${value.time3}"),
                HomeWidget.saveWidgetData<String>('asrTime', "${value.time4}"),
                HomeWidget.saveWidgetData<String>(
                    'maghribTime', "${value.time5}"),
                HomeWidget.saveWidgetData<String>('ishaTime', "${value.time6}"),
                HomeWidget.saveWidgetData<String>(
                    'titleDate', "${value.dateString}"),
              ]);
            });
          });
          return true;
        } catch (e) {
          debugPrint("Error in background task: $e");
          return false;
        }
      }
    }
    return false;
  });
}

@pragma("vm:entry-point")
void countdownTaskCallback() {
  // This callback will run in the background as part of the foreground service.
  // You can include your countdown logic here.
  FlutterForegroundTask.setTaskHandler(
      CountdownTaskHandler(flutterLocalNotificationsPlugin));
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 1) Initialize the plugin.
  // if (Platform.isAndroid) {
  //   await AndroidAlarmManager.initialize();
  //   await requestExactAlarmPermission();
  // }
  // Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
  // Workmanager().registerPeriodicTask(
  //   "updatePrayerTimesTask",
  //   "updatePrayerTimes",
  //   frequency: const Duration(hours: 20),
  // );
  runApp(MaterialApp(navigatorKey: GlobalVariable.navState, home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  StreamSubscription<Position>? positionStreamCurrent;
  LocationPermission? permission;
  PrayTimeModel prayTimeData = PrayTimeModel();

  bool _isRequestPinWidgetSupported = false;
  bool isLoadingPage = true;
  bool _timerRunning = false;
  String iosWidgetName = "MyHomeWidget";
  String groupAppId = "group.com.tnd.homewidget";
  String dataKey = "text1";

  @override
  void initState() {
    super.initState();
    HomeWidget.setAppGroupId(groupAppId);
    // HomeWidget.registerInteractivityCallback(interactiveCallback);
    getLocationAndPrayTimeApi();
    setttingLocalNoti();
    _checkPinability();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // _checkForWidgetLaunch();
    // HomeWidget.widgetClicked.listen(_launchedFromWidget);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  setttingLocalNoti() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_launcher');
    const DarwinInitializationSettings darwinSettingsIOS =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true);
    // 'ic_launcher' is the default app icon name in /android/app/src/main/res/mipmap-xxx

    const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings, iOS: darwinSettingsIOS);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        print('response: ${response.payload}');
        await handleNotificationResponse(response);
      },
    );
  }

  Future<void> handleNotificationResponse(NotificationResponse response) async {
    print('🔔 Notification tapped: ${response.payload}');
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => FullScreenCustom(
                  payload: response.payload,
                )));
    try {
      await AlarmService().playAlarm();
    } catch (e) {
      print('❌ Failed to play sound from notification: $e');
    }
  }

  setDataIos() async {
    List<Map<String, String>> prayerTimesList = [
      {"name": "Fajr", "time": prayTimeData.time1 ?? ""},
      {"name": "Sunrise", "time": prayTimeData.time2 ?? ""},
      {"name": "Dhuhr", "time": prayTimeData.time3 ?? ""},
      {"name": "Asr", "time": prayTimeData.time4 ?? ""},
      {"name": "Maghrib", "time": prayTimeData.time5 ?? ""},
      {"name": "Isha", "time": prayTimeData.time6 ?? ""},
    ];
    // countDownIos();
    String jsonData = jsonEncode(prayerTimesList);
    await HomeWidget.saveWidgetData<String>('prayerTimes', jsonData);
    await HomeWidget.saveWidgetData<String>(
        'text1', prayTimeData.dateString ?? "");
    await HomeWidget.updateWidget(iOSName: iosWidgetName);
    await LiveActivityService.requestPushNotificationPermission()
        .then((value) async {
      await LiveActivityService.registerDevice();
      await LiveActivityService().listener();
      await LiveActivityService()
          .startLiveActivityWithPrayerCountdown(prayTimeModel: prayTimeData);
    });
  }

  void countDownIos() {
    if (_timerRunning) return; // Prevent multiple timers
    _timerRunning = true;

    Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      // Replace the following with your real logic to compute the next prayer time.
      final nextPrayer = getNextPrayerTime();
      if (nextPrayer == null) {
        timer.cancel();
        _timerRunning = false;
        return;
      }
      final remaining = nextPrayer.difference(now);

      // When countdown reaches zero or negative, update the widget accordingly.
      if (remaining.inSeconds <= 0) {
        HomeWidget.saveWidgetData<String>('timer_value', "0 sec");
        HomeWidget.updateWidget(iOSName: iosWidgetName);
        // Optionally, you can refresh your prayer data here and restart the countdown.
        return;
      }

      // If more than 5 minutes remain, display a fixed countdown (e.g., "5 min")
      String timerValue = formatDuration(remaining);
      HomeWidget.saveWidgetData<String>('timer_value', timerValue);
      HomeWidget.updateWidget(iOSName: iosWidgetName);
      // if (remaining.inSeconds > 300) {
      //   HomeWidget.saveWidgetData<String>('timer_value', "5 min");
      //   HomeWidget.updateWidget(iOSName: iosWidgetName);
      // } else {
      //   // Otherwise, update the countdown dynamically
      //   String timerValue = formatDuration(remaining);
      //   HomeWidget.saveWidgetData<String>('timer_value', timerValue);
      //   HomeWidget.updateWidget(iOSName: iosWidgetName);
      // }
    });
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return "$minutes min $seconds sec";
  }

  void startCountdown() async {
    startCountdownForeground();
    // CountdownManager.startCountdown();
    // await updateCountdown();
  }

  Future<void> startCountdownForeground() async {
    // Start the foreground service.
    await FlutterForegroundTask.startService(
      notificationTitle: 'Countdown Running',
      notificationText: 'Your countdown is active',
      callback: countdownTaskCallback,
    );
  }

  void getLocationAndPrayTimeApi() async {
    if (!(await Geolocator.isLocationServiceEnabled())) {
      _checkSettingGPS(context);
    } else {
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showAlertDialog(context, "Alert! Location Allowed",
            "You denied permission of location,so you should go to setting for open location");
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }
      await Geolocator.getCurrentPosition().then((value) async {
        await ApiHttp()
            .fetchPrayerTimes(value.latitude, value.longitude, 7)
            .then((value) {
          setState(() {
            prayTimeData.dateString = value.dateString;
            prayTimeData.time1 = value.time1;
            prayTimeData.time2 = value.time2;
            prayTimeData.time3 = value.time3;
            prayTimeData.time4 = value.time4;
            prayTimeData.time5 = value.time5;
            prayTimeData.time6 = value.time6;
            savePrayerTimes(prayTimeData).then((test) {
              if (Platform.isAndroid) {
                funcForeGroundTaskInit().then((value1) {
                  pinHomePlatform();
                });
              } else {
                setDataIos();
              }
            });
            isLoadingPage = false;
          });
        });
      });
    }
  }

  DateTime? getNextPrayerTime() {
    // Assume these are your prayer times from API (adjust as necessary)
    List<String> prayerTimeStrings = [
      prayTimeData.time1 ?? "",
      prayTimeData.time2 ?? "",
      prayTimeData.time3 ?? "",
      prayTimeData.time4 ?? "",
      prayTimeData.time5 ?? "",
      prayTimeData.time6 ?? "",
    ];

    DateTime now = DateTime.now();
    List<DateTime> prayerTimes = [];

    for (String timeStr in prayerTimeStrings) {
      List<String> parts = timeStr.split(':');
      if (parts.length != 2) continue;
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      // Create a DateTime for the prayer today.
      DateTime prayerTime =
          DateTime(now.year, now.month, now.day, hour, minute);

      // If the prayer time is earlier than now and it logically belongs
      // to the early morning of the next day, adjust the date.
      if (prayerTime.isBefore(now) && hour < 6) {
        prayerTime = prayerTime.add(Duration(days: 1));
      }
      prayerTimes.add(prayerTime);
    }

    // Sort to get the upcoming prayer time
    prayerTimes.sort();
    for (DateTime prayer in prayerTimes) {
      if (now.isBefore(prayer)) {
        return prayer;
      }
    }
    return null;
  }

  Future<void> funcForeGroundTaskInit() async {
    await PermissionManager.requestPermissions();
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        priority: NotificationPriority.HIGH,
        onlyAlertOnce: true,
        enableVibration: true,
        playSound: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> savePrayerTimes(PrayTimeModel data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("time1", data.time1 ?? "");
    await prefs.setString("time2", data.time2 ?? "");
    await prefs.setString("time3", data.time3 ?? "");
    await prefs.setString("time4", data.time4 ?? "");
    await prefs.setString("time5", data.time5 ?? "");
    await prefs.setString("time6", data.time6 ?? "");
  }

  Future _sendDataAndroid() async {
    try {
      return Future.wait([
        HomeWidget.saveWidgetData<String>('fajrTime', "${prayTimeData.time1}"),
        HomeWidget.saveWidgetData<String>(
            'sunriseTime', "${prayTimeData.time2}"),
        HomeWidget.saveWidgetData<String>('dhuhrTime', "${prayTimeData.time3}"),
        HomeWidget.saveWidgetData<String>('asrTime', "${prayTimeData.time4}"),
        HomeWidget.saveWidgetData<String>(
            'maghribTime', "${prayTimeData.time5}"),
        HomeWidget.saveWidgetData<String>('ishaTime', "${prayTimeData.time6}"),
        HomeWidget.saveWidgetData<String>(
            'titleDate', "${prayTimeData.dateString}"),
      ]);
    } on PlatformException catch (exception) {
      debugPrint('Error Sending Data. $exception');
    }
  }

  Future _updateWidget() async {
    try {
      return Future.wait([
        HomeWidget.updateWidget(
          androidName: 'HomeWidgetExampleProvider',
          // iOSName: 'HomeWidgetExample',
        ),
        HomeWidget.updateWidget(
          qualifiedAndroidName:
              'com.example.homewidget.glance.HomeWidgetReceiver',
        ),
      ]);
    } on PlatformException catch (exception) {
      debugPrint('Error Updating Widget. $exception');
    }
  }

  Future<void> _sendAndUpdateAndroid() async {
    await _sendDataAndroid();
    await _updateWidget();
  }

  Future<void> _checkPinability() async {
    final isRequestPinWidgetSupported =
        await HomeWidget.isRequestPinWidgetSupported();
    if (mounted) {
      setState(() {
        _isRequestPinWidgetSupported = isRequestPinWidgetSupported ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomeWidget Example'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoadingPage
              ? Container(
                  alignment: Alignment.center,
                  height: MediaQuery.of(context).size.height,
                  child: LoadingAnimationWidget.discreteCircle(
                      color: Colors.black, size: 75))
              : Column(
                  children: [
                    ElevatedButton(
                      onPressed: _sendAndUpdateAndroid,
                      child: const Text('Send Data to Widget'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => FullScreenCustom()));
                      },
                      child: const Text('Pin Widget 4x2'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  pinHomePlatform() async {
    if (_isRequestPinWidgetSupported) {
      final widgets = await HomeWidget.getInstalledWidgets();
      setState(() {
        if (widgets.length <= 0) {
          _sendDataAndroid();
          startCountdown();
          HomeWidget.requestPinWidget(
            qualifiedAndroidName:
                'com.example.homewidget.glance.HomeWidgetReceiver',
          );
        } else {
          _showAlertDialog(context, "คุณเพิ่ม widget ไม่ได้แล้ว",
              "เนื่องจากมี widget ที่ pin ไว้แล้ว");
        }
      });
    }
  }

  static _checkSettingGPS(context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text("GPS Closed"),
        content: Text(
            "GPS ไม่ได้เปิดการใช้งานอยู่ในขณะนี้กรุณาไปที่ตั้งค่าเพื่อเปิด GPS"),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(
              "Setting",
              style: TextStyle(
                fontSize: 18,
                color: Colors.red,
              ),
            ),
            onPressed: () {
              Geolocator.openLocationSettings();
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  static _showAlertDialog(context, String title, String content) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(
              "Agree",
              style: TextStyle(
                fontSize: 18,
                color: Colors.red,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }
}

class GlobalVariable {
  static final GlobalKey<NavigatorState> navState = GlobalKey<NavigatorState>();
}
