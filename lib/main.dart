import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_widget/home_widget.dart';
import 'package:homewidget/api/api_http.dart';
import 'package:homewidget/api/res/prayer_time_response.dart';
import 'package:homewidget/countdown_manager.dart';
import 'package:homewidget/permission_manager.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'api/model/pray_time_model.dart';

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

void main() async {
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
  runApp(const MaterialApp(home: MyApp()));
}

Future<void> requestExactAlarmPermission() async {
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
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
  Timer? _timer;
  int _start = 10;
  bool isLoadingPage = true;
  String iosWidgetName = "MyHomeWidget";
  String groupAppId = "group.com.tnd.homewidget";
  String dataKey = "text1";

  @override
  void initState() {
    super.initState();
    HomeWidget.setAppGroupId(groupAppId);
    // HomeWidget.registerInteractivityCallback(interactiveCallback);
    getLocationAndPrayTimeApi();
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

  sendDataFollowPlatform() {
    if (Platform.isAndroid) {
      _sendDataAndroid();
    } else {
      _sendAndUpdateAndroid();
    }
  }

  setDataIos() async {
    HomeWidget.saveWidgetData<String>('prayerTimes', jsonEncode(prayTimeData));
    await HomeWidget.updateWidget(iOSName: iosWidgetName);
  }

  void startCountdown() async {
    await updateCountdown();
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
            funcForeGroundTaskInit().then((value1){
              prayTimeData.dateString = value.dateString;
              prayTimeData.time1 = value.time1;
              prayTimeData.time2 = value.time2;
              prayTimeData.time3 = value.time3;
              prayTimeData.time4 = value.time4;
              prayTimeData.time5 = value.time5;
              prayTimeData.time6 = value.time6;
              savePrayerTimes(prayTimeData);
              if (Platform.isAndroid) {
                pinHomePlatform();
              } else {
                setDataIos();
              }
              isLoadingPage = false;
            });
          });
        });
      });
    }
  }


  @pragma("vm:entry-point")
  Future<void> updateCountdown() async {
    // Start a timer that checks every second whether the remaining time is less than 5 minutes.
    Timer.periodic(Duration(seconds: 5), (timer) {
      DateTime now = DateTime.now();
      DateTime? nextPrayerTime = getNextPrayerTime();
      if (nextPrayerTime == null) {
        debugPrint("No upcoming prayer time available. Cancelling timer.");
        timer.cancel();
        return;
      }

      Duration remaining = nextPrayerTime.difference(now);

      // Use seconds for an accurate check:
      if (remaining.inSeconds < 5 * 60) {
        debugPrint("Remaining time (${remaining.inSeconds} sec) is less than 5 minutes; starting countdown update.");
        CountdownManager.startCountdown();
        // Optionally, cancel the timer once the countdown has started.
        timer.cancel();
      } else {
        debugPrint("Remaining time (${remaining.inSeconds} sec) is 5 minutes or more; waiting...");
      }
    });
  }

  DateTime? getNextPrayerTime() {
    // Assume these are your prayer times from API (adjust as necessary)
    List<String> prayerTimeStrings = [
      prayTimeData.time1 ?? "",
      prayTimeData.time2  ?? "",
      prayTimeData.time3  ?? "",
      prayTimeData.time4  ?? "",
      prayTimeData.time5  ?? "",
      prayTimeData.time6  ?? "",
    ];

    DateTime now = DateTime.now();
    List<DateTime> prayerTimes = [];

    for (String timeStr in prayerTimeStrings) {
      List<String> parts = timeStr.split(':');
      if (parts.length != 2) continue;
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      // Create a DateTime for the prayer today.
      DateTime prayerTime = DateTime(now.year, now.month, now.day, hour, minute);

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


  Future<void> funcForeGroundTaskInit() async{
    await PermissionManager.requestPermissions();
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
        'This notification appears when the foreground service is running.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
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

  Future _loadData() async {
    try {
      return Future.wait([
        HomeWidget.getWidgetData<String>('title', defaultValue: 'Default Title')
            .then((value) => _titleController.text = value ?? ''),
        HomeWidget.getWidgetData<String>(
          'message',
          defaultValue: 'Default Message',
        ).then((value) => _messageController.text = value ?? ''),
      ]);
    } on PlatformException catch (exception) {
      debugPrint('Error Getting Data. $exception');
    }
  }

  Future<void> _sendAndUpdateAndroid() async {
    await _sendDataAndroid();
    await _updateWidget();
  }

  void _launchedFromWidget(Uri? uri) {
    if (uri != null) {
      showDialog(
        context: context,
        builder: (buildContext) => AlertDialog(
          title: const Text('App started from HomeScreenWidget'),
          content: Text('Here is the URI: $uri'),
        ),
      );
    }
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
                        if (Platform.isAndroid) {
                          pinHomePlatform();
                        }
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
