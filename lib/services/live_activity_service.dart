import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';

import '../api/model/pray_time_model.dart';
import '../countdown_manager.dart';

/// Model sent to iOS Live Activity.
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

/// Service to drive the iOS Live Activity via MethodChannel/EventChannel.
class LiveActivityService {
  static const platform = MethodChannel('liveActivityChannel');
  static const listenerChannel = EventChannel('LiveActivityEvents');
  StreamSubscription? eventSubscription;

  /// Listen for native events (e.g. tokens).
  Future<void> listener() async {
    eventSubscription = listenerChannel.receiveBroadcastStream().listen(
          (event) async {
        switch (event['eventType']) {
          case 'pushToStartToken':
            log("pushToStartToken -> ${event['value']}");
            break;
          case 'pushToUpdateToken':
            log("pushToUpdateToken -> ${event['value']}");
            break;
        }
      },
    );
  }

  /// Ask iOS for push‑notification permission.
  static Future<void> requestPushNotificationPermission() async {
    try {
      await platform.invokeMethod("requestForNotificationPermission");
    } on PlatformException catch (e) {
      throw PlatformException(message: e.message, code: e.code);
    }
  }

  /// Register this device with your native Live Activity backend.
  static Future<void> registerDevice() async {
    try {
      await platform.invokeMethod("registerDevice");
    } on PlatformException catch (e) {
      throw PlatformException(message: e.message, code: e.code);
    }
  }

  /// Start the Live Activity with [data].
  Future<void> startLiveActivity({required LiveActivityModel data}) async {
    try {
      await platform.invokeMethod('startLiveActivity', data.toJson());
    } on PlatformException catch (e) {
      log("Failed to start Live Activity: ${e.message}");
    }
    log('LiveActivity start: ${data.toJson()}');
  }

  /// Update the Live Activity with [data].
  Future<void> updateLiveActivity({required LiveActivityModel data}) async {
    try {
      await platform.invokeMethod('updateLiveActivity', data.toJson());
    } on PlatformException catch (e) {
      log("Failed to update Live Activity: ${e.message}");
      rethrow;
    }
  }

  /// End the Live Activity.
  Future<void> endLiveActivity() async {
    try {
      await platform.invokeMethod('endLiveActivity');
    } on PlatformException catch (e) {
      log("Failed to end Live Activity: ${e.message}");
    }
  }

  /// Convenience: request permission, register, listen, then start countdown
  Future<void> startLiveActivityWithPrayerCountdown({
    required PrayTimeModel prayTimeModel,
  }) async {
    await requestPushNotificationPermission();
    await registerDevice();
    await listener();

    // Start the countdown manager
    PrayerCountdownManager(
      liveActivityService: this,
      prayTimeModel: prayTimeModel,
    ).startCountdown();
  }
}