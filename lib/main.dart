import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_widget/home_widget.dart';
import 'package:homewidget/api/api_http.dart';
import 'package:homewidget/api/res/prayer_time_response.dart';
import 'package:homewidget/countdown_manager.dart';
import 'package:homewidget/permission_manager.dart';
import 'package:homewidget/services/alram_service.dart';
import 'package:homewidget/services/full_screen_custom.dart';
import 'package:homewidget/services/live_activity_service.dart';
import 'package:homewidget/services/thai_province_map.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'api/model/pray_time_model.dart';

/// Used for Background Updates using Workmanager Plugin
@pragma("vm:entry-point")
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == "updatePrayerTimes") {
      if (Platform.isAndroid) {
        try {
          // String getRandomString(int length) {
          //   const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
          //       'abcdefghijklmnopqrstuvwxyz'
          //       '0123456789';
          //   final rand = Random.secure();
          //   return List.generate(
          //       length, (_) => _chars[rand.nextInt(_chars.length)]).join();
          // }
          await Geolocator.getCurrentPosition().then((value) async {
            await ApiHttp()
                .fetchPrayerTimes(value.latitude, value.longitude, 7)
                .then((valueApi) async {
              Future.wait([
                HomeWidget.saveWidgetData<String>(
                    'fajrTime', "${valueApi.time1}"),
                HomeWidget.saveWidgetData<String>(
                    'sunriseTime', "${valueApi.time2}"),
                HomeWidget.saveWidgetData<String>(
                    'dhuhrTime', "${valueApi.time3}"),
                HomeWidget.saveWidgetData<String>(
                    'asrTime', "${valueApi.time4}"),
                HomeWidget.saveWidgetData<String>(
                    'maghribTime', "${valueApi.time5}"),
                HomeWidget.saveWidgetData<String>(
                    'ishaTime', "${valueApi.time6}"),
                HomeWidget.saveWidgetData<String>(
                    'titleDate', valueApi.dateString),
              ]);
              await HomeWidget.updateWidget(
                androidName: 'HomeWidgetExampleProvider',
                qualifiedAndroidName:
                    'com.example.homewidget.glance.HomeWidgetReceiver',
              );
              print('updateSuccesss15,minute');
            });
          });
          return Future.value(true);
        } catch (e) {
          debugPrint("Error in background task: $e");
          return Future.value(false);
        }
      } else {
        try {
          print('updateIOS');
          await Geolocator.getCurrentPosition().then((value) async {
            await ApiHttp()
                .fetchPrayerTimes(value.latitude, value.longitude, 7)
                .then((prayTimeData) async {
              List<Map<String, String>> prayerTimesList = [
                {"name": "Fajr", "time": prayTimeData.time1},
                {"name": "Sunrise", "time": prayTimeData.time2},
                {"name": "Dhuhr", "time": prayTimeData.time3},
                {"name": "Asr", "time": prayTimeData.time4},
                {"name": "Maghrib", "time": prayTimeData.time5},
                {"name": "Isha", "time": prayTimeData.time6},
              ];
              String jsonData = jsonEncode(prayerTimesList);
              await HomeWidget.saveWidgetData<String>('prayerTimes', jsonData);
              await HomeWidget.saveWidgetData<String>(
                  'text1', prayTimeData.dateString);
              await HomeWidget.updateWidget(iOSName: "MyHomeWidget");
            });
          });
          return Future.value(true);
        } catch (e) {
          debugPrint("Error in background task IOS: $e");
          return Future.value(false);
        }
      }
    }
    return Future.value(true);
  });
}

@pragma("vm:entry-point")
Future<void> interactiveCallback(Uri? data) async {
  print("Refresh action triggered ${data}");
  if (data?.host == 'actionrefresh') {
    // Handle the refresh action
    try {
      await Geolocator.getCurrentPosition().then((value) async {
        await ApiHttp()
            .fetchPrayerTimes(value.latitude, value.longitude, 7)
            .then((valueApi) async {
          List<Placemark> placemark = await placemarkFromCoordinates(
            value.latitude,
            value.longitude,
          );
          String provice = ThaiProvinceMap.localizedAdminArea(
              placemark[0].administrativeArea ?? "");
          Future.wait([
            HomeWidget.saveWidgetData<String>('fajrTime', "${valueApi.time1}"),
            HomeWidget.saveWidgetData<String>(
                'sunriseTime', "${valueApi.time2}"),
            HomeWidget.saveWidgetData<String>('dhuhrTime', "${valueApi.time3}"),
            HomeWidget.saveWidgetData<String>('asrTime', "${valueApi.time4}"),
            HomeWidget.saveWidgetData<String>(
                'maghribTime', "${valueApi.time5}"),
            HomeWidget.saveWidgetData<String>('ishaTime', "${valueApi.time6}"),
            HomeWidget.saveWidgetData<String>('titleDate', "${valueApi.dateString}"),
            HomeWidget.saveWidgetData<String>('location', provice),
          ]);
          await HomeWidget.updateWidget(
            androidName: 'HomeWidgetExampleProvider',
            qualifiedAndroidName:
                'com.example.homewidget.glance.HomeWidgetReceiver',
          );
        });
      });
    } catch (e) {
      debugPrint("Error in interactive callback: $e");
    }
  }
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
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );
  if (Platform.isAndroid) {
    Workmanager().registerPeriodicTask(
      "updatePrayerTimesTask",
      "updatePrayerTimes",
      existingWorkPolicy: ExistingWorkPolicy.replace,
      frequency: const Duration(days: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  } else {
    try {
      Workmanager().registerOneOffTask(
        "updatePrayerTimes",
        "updatePrayerTimes",
        initialDelay: Duration.zero,
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } catch (e) {
      debugPrint("Background scheduling error: ${e}");
    }
  }
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
    HomeWidget.registerInteractivityCallback(interactiveCallback);
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

  setDataIos(String province) async {
    List<Map<String, String>> prayerTimesList = [
      {"name": "ศุบฮิ", "time": prayTimeData.time1 ?? ""},
      {"name": "ชุรูก", "time": prayTimeData.time2 ?? ""},
      {"name": "ซุฮฺริ", "time": prayTimeData.time3 ?? ""},
      {"name": "อัศริ", "time": prayTimeData.time4 ?? ""},
      {"name": "มัฆริบ", "time": prayTimeData.time5 ?? ""},
      {"name": "อิชาอฺ", "time": prayTimeData.time6 ?? ""},
    ];
    // countDownIos();
    String jsonData = jsonEncode(prayerTimesList);
    await HomeWidget.saveWidgetData<String>('prayerTimes', jsonData);
    await HomeWidget.saveWidgetData<String>(
        'text1', prayTimeData.dateString ?? "");
    await HomeWidget.saveWidgetData<String>(
        'text2', province);
    print('rpovince $province');
    await HomeWidget.updateWidget(iOSName: iosWidgetName);
    // await LiveActivityService.requestPushNotificationPermission()
    //     .then((value) async {
    //   await LiveActivityService.registerDevice();
    //   await LiveActivityService().listener();
    //   await LiveActivityService()
    //       .startLiveActivityWithPrayerCountdown(prayTimeModel: prayTimeData);
    // });
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
      // callback: countdownTaskCallback,
    );
  }

  Future<void> getLocationAndPrayTimeApi() async {
    // 1) เช็คว่า GPS เปิดอยู่หรือไม่
    if (!await Geolocator.isLocationServiceEnabled()) {
      _checkSettingGPS(context);
      return;
    }

    // 2) ขอ permission แบบ while-in-use
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      _showAlertDialog(
        context,
        "Alert! Location Allowed",
        "คุณปฏิเสธการเข้าถึงตำแหน่งไปแล้ว กรุณาไปที่ Settings เพื่อเปิด Location",
      );
      return;
    }

    // 3) ขอ permission แบบ always (background)
    if (Platform.isAndroid) {
      if (permission != LocationPermission.always) {
        final bgStatus = await Permission.locationAlways.request();
        if (!bgStatus.isGranted) {
          _showAlertDialog(context, "Alert! Location Allowed",
              "You denied permission of location,so you should go to setting for open location");
          return;
        }
      }
    } else {
      await ensureBackgroundLocation(context);
    }

    try {
      final pos = await Geolocator.getCurrentPosition();
      final resp = await ApiHttp().fetchPrayerTimes(
        pos.latitude,
        pos.longitude,
        7,
      );

      setState(() {
        prayTimeData
          ..dateString = resp.dateString
          ..time1 = resp.time1
          ..time2 = resp.time2
          ..time3 = resp.time3
          ..time4 = resp.time4
          ..time5 = resp.time5
          ..time6 = resp.time6;
        isLoadingPage = false;
      });

      await savePrayerTimes(prayTimeData);
      List<Placemark> placemark = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      String provice = ThaiProvinceMap.localizedAdminArea(
          placemark[0].administrativeArea ?? "");
      if (Platform.isAndroid) {
        await funcForeGroundTaskInit();
        pinHomePlatform(provice);
      } else {
        setDataIos(provice);
      }
    } catch (e) {
      debugPrint("Error fetching location/API: $e");
    }
  }

  Future<bool> ensureBackgroundLocation(BuildContext ctx) async {
    // 1) ขอ while-in-use
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever) {
      _showAlertDialog(ctx, 'การเข้าถึง location ถูกปฏิเสธ',
          'กรุณาเปิด Location ใน Settings');
      return false;
    }

    // 2) ถ้าได้แค่ while-in-use ลองขอ always ผ่าน permission_handler
    if (p != LocationPermission.always) {
      final status = await Permission.locationAlways.request();
      if (!status.isGranted) {
        _showAlertDialog(ctx, 'การเข้าถึง location ถูกปฏิเสธ',
            'กรุณาไปที่ Setting เพื่อตั้งค่า Location Always');
        return false;
      }
    }

    // ตอนนี้ได้ always แล้ว
    return true;
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

  Future _sendDataAndroid(String province) async {
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
        HomeWidget.saveWidgetData<String>('location', province),
      ]);
    } on PlatformException catch (exception) {
      debugPrint('Error Sending Data. $exception');
    }
  }

  Future _updateWidget() async {
    try {
      await Geolocator.getCurrentPosition().then((value) async {
        await ApiHttp()
            .fetchPrayerTimes(value.latitude, value.longitude, 7)
            .then((valueApi) async {
          Future.wait([
            HomeWidget.saveWidgetData<String>('fajrTime', "${valueApi.time1}"),
            HomeWidget.saveWidgetData<String>(
                'sunriseTime', "${valueApi.time2}"),
            HomeWidget.saveWidgetData<String>('dhuhrTime', "${valueApi.time3}"),
            HomeWidget.saveWidgetData<String>('asrTime', "${valueApi.time4}"),
            HomeWidget.saveWidgetData<String>(
                'maghribTime', "${valueApi.time5}"),
            HomeWidget.saveWidgetData<String>('ishaTime', "${valueApi.time6}"),
            HomeWidget.saveWidgetData<String>(
                'titleDate', "${valueApi.dateString}"),
          ]);
          await HomeWidget.updateWidget(
            androidName: 'HomeWidgetExampleProvider',
            qualifiedAndroidName:
                'com.example.homewidget.glance.HomeWidgetReceiver',
          );
          print('updateSuccesss15,minute');
        });
      });
    } on PlatformException catch (exception) {
      debugPrint('Error Updating Widget. $exception');
    }
  }

  Future<void> _sendAndUpdateAndroid() async {
    await _sendDataAndroid("");
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Trigger background task manually
          Workmanager().registerOneOffTask(
            "manualRefresh", // unique name
            "updatePrayerTimes", // ชื่อ task เดิมที่เรากำหนดไว้
            initialDelay: Duration.zero,
          );
        },
        child: Icon(Icons.refresh),
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
                        pinHomePlatform("");
                      },
                      child: const Text('Pin Widget 4x2'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  pinHomePlatform(String province) async {
    if (_isRequestPinWidgetSupported) {
      final widgets = await HomeWidget.getInstalledWidgets();
      setState(() {
        if (widgets.length <= 0) {
          _sendDataAndroid(province);
          // startCountdown();
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
              "Setting",
              style: TextStyle(
                fontSize: 18,
                color: Colors.red,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
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
