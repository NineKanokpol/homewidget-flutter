import 'package:audioplayers/audioplayers.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();

  factory AlarmService() => _instance;

  AlarmService._internal();

  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _hasAlarmFired = false;

  bool get isAlarmPlaying => _isPlaying;
  AudioPlayer? get player => _player;

  Future<void> playAlarm() async {
    if (_isPlaying || _hasAlarmFired) return;

    _hasAlarmFired = true;
    _player = AudioPlayer();
    await _player!.setReleaseMode(ReleaseMode.loop);

    _player!.onPlayerStateChanged.listen((state) {
      print("🔊 Alarm state: $state");
      _isPlaying = state == PlayerState.playing;
    });

    await _player!.play(AssetSource('audio/alarm_sound.mp3'), volume: 1.0);
  }

  Future<void> stopAlarm() async {
    if (_player != null) {
      await _player!.stop();
      await _player!.release();
      _player = null;
      _isPlaying = false;
      _hasAlarmFired = false;
    }
  }
}