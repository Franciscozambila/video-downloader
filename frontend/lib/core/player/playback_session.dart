import 'package:flutter/foundation.dart';

class PlaybackSession extends ChangeNotifier {
  PlaybackSession._();

  static final PlaybackSession instance = PlaybackSession._();

  String? currentPath;
  String? currentTitle;
  bool isAudio = false;
  List<String> queue = const [];
  int currentIndex = 0;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double volume = 0.8;
  bool shuffle = false;
  String repeatMode = 'off';

  bool get hasActivePlayback => currentPath != null && currentPath!.isNotEmpty;

  void setCurrentMedia({
    required String title,
    required String path,
    required bool isAudioMedia,
    List<String>? queueItems,
    int index = 0,
  }) {
    currentTitle = title;
    currentPath = path;
    isAudio = isAudioMedia;
    if (queueItems != null) {
      queue = List<String>.from(queueItems);
    }
    currentIndex = index;
    notifyListeners();
  }

  void setPlaybackState({
    bool? playing,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? shuffle,
    String? repeatMode,
  }) {
    if (playing != null) isPlaying = playing;
    if (position != null) this.position = position;
    if (duration != null) this.duration = duration;
    if (volume != null) this.volume = volume;
    if (shuffle != null) this.shuffle = shuffle;
    if (repeatMode != null) this.repeatMode = repeatMode;
    notifyListeners();
  }

  void clear() {
    currentPath = null;
    currentTitle = null;
    queue = const [];
    currentIndex = 0;
    isPlaying = false;
    position = Duration.zero;
    duration = Duration.zero;
    notifyListeners();
  }
}
