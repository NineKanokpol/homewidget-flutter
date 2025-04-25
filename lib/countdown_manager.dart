import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:homewidget/services/live_activity_service.dart';

import '../api/model/pray_time_model.dart';

/// Manages the 30‑second countdown before each prayer time,
/// with an extra print-tick during the wait phase.
class PrayerCountdownManager {
  final LiveActivityService liveActivityService;
  final PrayTimeModel prayTimeModel;

  Timer? _initialCountdownTimer;
  Timer? _periodicTimer;

  PrayerCountdownManager({
    required this.liveActivityService,
    required this.prayTimeModel,
  });

  /// Kick off: ถ้าเหลือ ≤30s → เริ่มทันที, else รอพร้อมนับถอยหลัง
  void startCountdown() {
    final now = DateTime.now();
    final nextPrayer = _findNextPrayer(now);
    if (nextPrayer == null) return;

    final secondsUntilPrayer = nextPrayer.difference(now).inSeconds;
    final startAfter = max(secondsUntilPrayer - 30, 0);

    // ยกเลิก timer เก่าทั้งหมดก่อน
    _initialCountdownTimer?.cancel();
    _periodicTimer?.cancel();

    if (startAfter == 0) {
      print("⏱ เริ่ม 30s countdown ทันที!");
      _beginLiveActivity(nextPrayer);
    } else {
      int remaining = startAfter;
      print("⏳ รอจนถึง T-30s: เหลือ $remaining วินาที");

      // ใช้ Timer.periodic นับถอยหลังทีละวินาที พร้อมพิมพ์สถานะ
      _initialCountdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        remaining--;
        if (remaining > 0) {
          print("⏳ เริ่มนับถอยหลังในอีก $remaining วินาที");
        } else {
          timer.cancel();
          print("⏱ ถึงเวลา T-30s แล้ว เริ่ม 30s countdown");
          _beginLiveActivity(nextPrayer);
        }
      });
    }
  }

  /// หา next prayer time ของวัน / วันถัดไป
  DateTime? _findNextPrayer(DateTime now) {
    print('timeEach ${prayTimeModel.toJson()}');
    final times = [
      prayTimeModel.time1,
      prayTimeModel.time2,
      prayTimeModel.time3,
      prayTimeModel.time4,
      prayTimeModel.time5,
      prayTimeModel.time6,
    ].where((t) => t != null && t.isNotEmpty);

    final candidates = <DateTime>[];
    for (var t in times) {
      final parts = t!.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final min = int.tryParse(parts[1]) ?? 0;
      var dt = DateTime(now.year, now.month, now.day, hour, min);
      if (dt.isBefore(now)) dt = dt.add(Duration(days: 1));
      candidates.add(dt);
    }

    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.first;
  }

  /// สตาร์ท Live Activity และอัปเดตทุกวินาที (30 → 0)
  void _beginLiveActivity(DateTime prayerTime) async {
    await liveActivityService.startLiveActivity(
      data: LiveActivityModel(
        carModel: 'Sedan',
        driverCode: 'DR123',
        minutesToArrive: 0,
        carArriveProgress: 30,
      ),
    );

    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      final now = DateTime.now();
      final remaining = prayerTime.difference(now).inSeconds;
      if (remaining <= 0) {
        timer.cancel();
        print("✅ Countdown จบแล้ว");
        await liveActivityService.endLiveActivity();
        return;
      }

      final secs = remaining.clamp(0, 30);
      print("⏱ Countdown: $secs วินาที");

      final data = LiveActivityModel(
        carModel: 'Sedan',
        driverCode: 'DR123',
        minutesToArrive: 0,
        carArriveProgress: secs,
      );

      try {
        await liveActivityService.updateLiveActivity(data: data);
      } on PlatformException {
        // auto‑reconnect on failure
        print("❌ เกิดข้อผิดพลาดในการอัปเดต จะแก้ไขและสตาร์ทใหม่");
        await LiveActivityService.registerDevice();
        await liveActivityService.startLiveActivity(data: data);
      }
    });
  }

  /// ยกเลิกทุก timer เมื่อหยุดนับถอยหลัง
  void stopCountdown() {
    _initialCountdownTimer?.cancel();
    _periodicTimer?.cancel();
  }
}