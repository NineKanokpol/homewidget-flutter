import 'dart:async';

import 'package:homewidget/services/live_activity_service.dart';

class CountdownManager {
  final DateTime expirationTime;
  Timer? _timer;
  final LiveActivityService liveActivityService;
  final LiveActivityModel baseModel;

  CountdownManager({
    required this.expirationTime,
    required this.liveActivityService,
    required this.baseModel,
  });

  void startCountdown() {
    // Update every second.
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      // Compute the remaining seconds dynamically.
      int remainingSeconds = expirationTime.difference(DateTime.now()).inSeconds;

      if (remainingSeconds <= 0) {
        timer.cancel();
        // End the activity when countdown is finished.
        liveActivityService.endLiveActivity();
      } else {
        // Create an updated model using the computed remaining seconds.
        LiveActivityModel updatedModel = LiveActivityModel(
          carModel: baseModel.carModel,
          driverCode: baseModel.driverCode,
          minutesToArrive: remainingSeconds, // updated value
          carArriveProgress: baseModel.carArriveProgress,
        );
        liveActivityService.updateLiveActivity(data: updatedModel);
      }
    });
  }

  void cancelCountdown() {
    _timer?.cancel();
  }
}
