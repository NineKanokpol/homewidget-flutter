import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_widget/home_widget.dart';
import 'package:homewidget/api/api_http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'api/model/pray_time_model.dart';

/// Used for Background Updates using Workmanager Plugin
@pragma("vm:entry-point")
void callbackDispatcher() async {
  Workmanager().executeTask((taskName, inputData) async {
    final now = DateTime.now();
    return Future.wait<bool?>([
      HomeWidget.saveWidgetData(
        'countdown',
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      ),
    ]).then((value) async {
      Future.wait<bool?>([
        HomeWidget.updateWidget(
          name: 'HomeWidgetExampleProvider',
          iOSName: 'HomeWidgetExample',
        ),
        if (Platform.isAndroid)
          HomeWidget.updateWidget(
            qualifiedAndroidName:
                'com.example.homewidget.glance.HomeWidgetReceiver',
          ),
      ]);
      return !value.contains(false);
    });
  });
}

Future<void> updateCountdown() async {
  final prefs = await SharedPreferences.getInstance();
  int lastTime =
      prefs.getInt("timer_value") ?? 60; // นับถอยหลังเริ่มที่ 60 วินาที

  if (lastTime > 0) {
    lastTime--;
  } else {
    lastTime = 60;
  }

  // บันทึกค่าใหม่ลง SharedPreferences
  await prefs.setInt("timer_value", lastTime);

  // อัปเดต Widget
  await HomeWidget.saveWidgetData<int>("timer_value", lastTime);
  Future.wait<bool?>([
    HomeWidget.updateWidget(
      name: 'HomeWidgetExampleProvider',
      iOSName: 'HomeWidgetExample',
    ),
    if (Platform.isAndroid)
      HomeWidget.updateWidget(
        qualifiedAndroidName:
            'com.example.homewidget.glance.HomeWidgetReceiver',
      ),
  ]);

  await AndroidAlarmManager.oneShot(
    const Duration(seconds: 1),
    0,
    updateCountdown,
    exact: true,
    wakeup: true,
  );
}

/// Called when Doing Background Work initiated from Widget
@pragma("vm:entry-point")
Future<void> interactiveCallback(Uri? data) async {
  if (data?.host == 'titleclicked') {
    final greetings = [
      'Hello',
      'Hallo',
      'Bonjour',
      'Hola',
      'Ciao',
      '哈洛',
      '안녕하세요',
      'xin chào',
    ];
    final selectedGreeting = greetings[Random().nextInt(greetings.length)];
    await HomeWidget.setAppGroupId('YOUR_GROUP_ID');
    await HomeWidget.saveWidgetData<String>('title', selectedGreeting);
    await HomeWidget.updateWidget(
      name: 'HomeWidgetExampleProvider',
      iOSName: 'HomeWidgetExample',
    );
    if (Platform.isAndroid) {
      await HomeWidget.updateWidget(
        qualifiedAndroidName:
            'com.example.homewidget.glance.HomeWidgetReceiver',
      );
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
  if(Platform.isAndroid){
    await AndroidAlarmManager.initialize();
    await requestExactAlarmPermission();
  }
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

  @override
  void initState() {
    super.initState();
    HomeWidget.setAppGroupId('YOUR_GROUP_ID');
    HomeWidget.registerInteractivityCallback(interactiveCallback);
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
            prayTimeData.dateString = value.dateString;
            prayTimeData.time1 = value.time1;
            prayTimeData.time2 = value.time2;
            prayTimeData.time3 = value.time3;
            prayTimeData.time4 = value.time4;
            prayTimeData.time5 = value.time5;
            prayTimeData.time6 = value.time6;
            isLoadingPage = false;
          });
        });
      });
    }
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  Future _sendData() async {
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
            'hijriDate', "${prayTimeData.dateString}"),
      ]);
    } on PlatformException catch (exception) {
      debugPrint('Error Sending Data. $exception');
    }
  }

  Future _updateWidget() async {
    try {
      return Future.wait([
        HomeWidget.updateWidget(
          name: 'HomeWidgetExampleProvider',
          iOSName: 'HomeWidgetExample',
        ),
        if (Platform.isAndroid)
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

  Future<void> _sendAndUpdate() async {
    await _sendData();
    await _updateWidget();
  }

  void _checkForWidgetLaunch() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_launchedFromWidget);
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

  void _startBackgroundUpdate() {
    Workmanager().registerPeriodicTask(
      '1',
      'widgetBackgroundUpdate',
      frequency: const Duration(minutes: 15),
    );
  }

  void _stopBackgroundUpdate() {
    Workmanager().cancelByUniqueName('1');
  }

  Future<void> _getInstalledWidgets() async {
    try {
      final widgets = await HomeWidget.getInstalledWidgets();
      if (!mounted) return;

      String getText(HomeWidgetInfo widget) {
        if (Platform.isIOS) {
          return 'iOS Family: ${widget.iOSFamily}, iOS Kind: ${widget.iOSKind}';
        } else {
          return 'Android Widget id: ${widget.androidWidgetId}, '
              'Android Class Name: ${widget.androidClassName}, '
              'Android Label: ${widget.androidLabel}';
        }
      }

      await showDialog(
        context: context,
        builder: (buildContext) => AlertDialog(
          title: const Text('Installed Widgets'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Number of widgets: ${widgets.length}'),
              const Divider(),
              for (final widget in widgets)
                Text(
                  getText(widget),
                ),
            ],
          ),
        ),
      );
    } on PlatformException catch (exception) {
      debugPrint('Error getting widget information. $exception');
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
                      onPressed: _sendAndUpdate,
                      child: const Text('Send Data to Widget'),
                    ),
                      ElevatedButton(
                        onPressed: () async {
                          pinHomePlatform();
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
    if(Platform.isAndroid){
      if (_isRequestPinWidgetSupported){
        final widgets =
            await HomeWidget.getInstalledWidgets();
        setState(() {
          if (widgets.length == 1) {
            _sendData();
            startCountdown();
            HomeWidget.requestPinWidget(
              qualifiedAndroidName:
              'com.example.homewidget.glance.HomeWidgetReceiver',
            );
          } else {
            _showAlertDialog(
                context,
                "คุณเพิ่ม widget ไม่ได้แล้ว",
                "เนื่องจากมี widget ที่ pin ไว้แล้ว");
          }
        });
      }
    }else{

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
