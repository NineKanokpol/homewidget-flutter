import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';

import '../countdown_manager.dart';

class LiveActivityModel {
  final String carModel;
  final String driverCode;
  final int minutesToArrive;
  final int carArriveProgress;

  LiveActivityModel({
    required this.carModel,
    required this.driverCode,
    required this.minutesToArrive,
    required this.carArriveProgress,
  });

  Map<String, dynamic> toJson() => {
    'carModel': carModel,
    'driverCode': driverCode,
    'minutesToArrive': minutesToArrive,
    'carArriveProgress': carArriveProgress,
  };
}

class LiveActivityService {
  static const platform = MethodChannel('liveActivityChannel');
  static const listenerChannel = EventChannel('LiveActivityEvents');
  StreamSubscription? eventSubscription;

  Future<void> listener() async {
    eventSubscription = listenerChannel.receiveBroadcastStream().listen(
          (event) async {
        switch (event['eventType']) {
          case 'pushToStartToken':
            dynamic tokenValue = event['value'];
            log("pushToStartToken -> $tokenValue");
            break;
          case 'pushToUpdateToken':
            dynamic tokenValue = event['value'];
            log("pushToUpdateToken -> $tokenValue");
            break;
        }
      },
    );
  }

  static Future<void> requestPushNotificationPermission() async {
    try {
      await platform.invokeMethod("requestForNotificationPermission");
    } on PlatformException catch (e) {
      throw PlatformException(message: e.message, code: e.code);
    }
  }

  static Future<void> registerDevice() async {
    try {
      await platform.invokeMethod("registerDevice");
    } on PlatformException catch (e) {
      throw PlatformException(message: e.message, code: e.code);
    }
  }

  // 1) Just start the live activity; don’t call the countdown from here.
  Future<void> startLiveActivity({required LiveActivityModel data}) async {
    try {
      await platform.invokeMethod(
        'startLiveActivity',
        data.toJson(),
      );
    } on PlatformException catch (e) {
      log("Failed to start live activity: '${e.message}'.");
    }
    print('startLiveActivity: data -> ${data.toJson()}');
  }

  // 2) Update with new data (e.g., every second).
  Future<void> updateLiveActivity({required LiveActivityModel data}) async {
    try {
      await platform.invokeMethod(
        'updateLiveActivity',
        data.toJson(),
      );
    } on PlatformException catch (e) {
      log("Failed to update live activity: '${e.message}'.");
    }
  }

  // 3) End the activity once the countdown hits zero.
  Future<void> endLiveActivity() async {
    try {
      await platform.invokeMethod('endLiveActivity');
    } on PlatformException catch (e) {
      log("Failed to end live activity: '${e.message}'.");
    }
  }

  // 4) Start countdown from 300 seconds in one place.
  //    Notice we do NOT create a new LiveActivityService here
  //    nor do we call startLiveActivity() from inside another start method.
  Future<void> startLiveActivityWithCountdown() async {
    const int durationSeconds = 300;
    // Calculate the expiration time.
    final DateTime expirationTime = DateTime.now().add(Duration(seconds: durationSeconds));

    // Use the duration (in seconds) for initial display.
    LiveActivityModel initialData = LiveActivityModel(
      carModel: 'Sedan',
      driverCode: 'DR123',
      minutesToArrive: durationSeconds, // initial value for UI purposes
      carArriveProgress: 0,
    );

    // Step A: Start the live activity.
    await startLiveActivity(data: initialData);

    // Step B: Kick off the countdown, passing the expiration time.
    CountdownManager countdownManager = CountdownManager(
      expirationTime: expirationTime,
      liveActivityService: this, // Use THIS instance
      baseModel: initialData,
    );
    countdownManager.startCountdown();
  }
}