import 'package:just_audio/just_audio.dart';

class PlaybackService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayer get player => _audioPlayer;

  Future<void> open(String path) async {
    await _audioPlayer.setFilePath(path);
  }

  Future<void> play() async => _audioPlayer.play();
  Future<void> pause() async => _audioPlayer.pause();
  Future<void> seek(Duration position) async => _audioPlayer.seek(position);
  Future<void> setVolume(double volume) async => _audioPlayer.setVolume(volume);
  Future<void> dispose() async => _audioPlayer.dispose();
}
