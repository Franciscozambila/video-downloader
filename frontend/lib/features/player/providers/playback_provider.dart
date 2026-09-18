import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class PlaybackProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? currentPath;
  String? currentTitle;
  List<String> queue = const [];
  int currentIndex = 0;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isPlaying = false;
  double volume = 0.8;
  bool shuffle = false;
  String repeatMode = 'off';

  AudioPlayer get audioPlayer => _audioPlayer;

  Future<void> open(String path, {String? title, List<String>? queueItems, int index = 0}) async {
    currentPath = path;
    currentTitle = title ?? path.split('/').last;
    if (queueItems != null) {
      queue = queueItems;
    }
    currentIndex = index;
    await _audioPlayer.setFilePath(path);
    _audioPlayer.playerStateStream.listen((state) {
      isPlaying = state.playing;
      position = _audioPlayer.position;
      duration = _audioPlayer.duration ?? Duration.zero;
      notifyListeners();
    });
    _audioPlayer.positionStream.listen((event) {
      position = event;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> play() async {
    await _audioPlayer.play();
    isPlaying = true;
    notifyListeners();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    isPlaying = false;
    notifyListeners();
  }

  Future<void> seek(Duration value) async {
    await _audioPlayer.seek(value);
    position = value;
    notifyListeners();
  }

  Future<void> setVolume(double value) async {
    volume = value;
    await _audioPlayer.setVolume(value);
    notifyListeners();
  }

  Future<void> next() async {
    if (queue.isEmpty) return;
    if (currentIndex < queue.length - 1) {
      currentIndex += 1;
    } else if (repeatMode == 'all') {
      currentIndex = 0;
    }
    currentPath = queue[currentIndex];
    currentTitle = currentPath!.split('/').last;
    await _audioPlayer.setFilePath(currentPath!);
    notifyListeners();
  }

  Future<void> previous() async {
    if (queue.isEmpty) return;
    if (currentIndex > 0) {
      currentIndex -= 1;
    } else if (repeatMode == 'all') {
      currentIndex = queue.length - 1;
    }
    currentPath = queue[currentIndex];
    currentTitle = currentPath!.split('/').last;
    await _audioPlayer.setFilePath(currentPath!);
    notifyListeners();
  }

  Future<void> disposeAudio() async {
    await _audioPlayer.dispose();
  }
}
