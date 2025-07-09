// services/audio_service.dart
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playAlert() async {
    await _player.play(AssetSource('audio/alert.mp3'));
  }

  static Future<void> playLogin() async {
    await _player.play(AssetSource('audio/login.mp3'));
  }

  static Future<void> playDing() async {
    await _player.play(AssetSource('audio/ding.mp3'));
  }
}