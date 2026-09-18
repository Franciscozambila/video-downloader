import 'package:flutter/foundation.dart';

class PlayerStateModel extends ChangeNotifier {
  String? currentMedia;
  int currentIndex = 0;
  List<String> queue = const [];
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double volume = 1.0;
  double boost = 1.0;
  bool shuffle = false;
  String repeatMode = 'off';
  Duration? sleepTimer;

  void setCurrentMedia(String? media, {int index = 0, List<String>? queueItems}) {
    currentMedia = media;
    currentIndex = index;
    if (queueItems != null) {
      queue = queueItems;
    }
    notifyListeners();
  }

  void setPlaybackState({
    bool? playing,
    Duration? position,
    Duration? duration,
    double? volume,
    double? boost,
    bool? shuffle,
    String? repeatMode,
    Duration? sleepTimer,
  }) {
    if (playing != null) isPlaying = playing;
    if (position != null) this.position = position;
    if (duration != null) this.duration = duration;
    if (volume != null) this.volume = volume;
    if (boost != null) this.boost = boost;
    if (shuffle != null) this.shuffle = shuffle;
    if (repeatMode != null) this.repeatMode = repeatMode;
    if (sleepTimer != null) this.sleepTimer = sleepTimer;
    notifyListeners();
  }
}
