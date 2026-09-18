import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

class LocalPlaybackService {
  AudioPlayer? _audioPlayer;
  VideoPlayerController? _videoController;

  AudioPlayer get audioPlayer => _audioPlayer ??= AudioPlayer();

  Future<void> openAudio(String path) async {
    final player = audioPlayer;
    await player.setFilePath(path);
  }

  Future<void> playAudio(String path) async {
    final player = audioPlayer;
    await player.setFilePath(path);
    await player.play();
  }

  Future<void> openVideo(String path) async {
    if (_videoController != null) {
      await _videoController!.dispose();
    }
    _videoController = VideoPlayerController.file(File(path));
    await _videoController!.initialize();
  }

  VideoPlayerController? get videoController => _videoController;

  Future<void> dispose() async {
    await _audioPlayer?.dispose();
    await _videoController?.dispose();
  }
}
