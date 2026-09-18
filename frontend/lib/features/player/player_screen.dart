import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

class PlayerScreen extends StatefulWidget {
  final String title;
  final String path;
  final bool isAudio;

  const PlayerScreen({
    super.key,
    required this.title,
    required this.path,
    this.isAudio = false,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  AudioPlayer? _audioPlayer;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    setState(() => _loading = true);

    try {
      if (widget.isAudio) {
        _audioPlayer = AudioPlayer();
        await _audioPlayer!.setFilePath(widget.path);
      } else {
        _videoController = VideoPlayerController.file(File(widget.path));
        await _videoController!.initialize();
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false,
          looping: false,
          allowFullScreen: true,
          allowPlaybackSpeedChanging: true,
        );
      }
    } catch (e) {
      debugPrint('Player init failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.isAudio) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note_rounded, size: 80),
              const SizedBox(height: 16),
              Text(widget.title, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () async => _audioPlayer?.seek(const Duration(seconds: -10)),
                    icon: const Icon(Icons.replay_10_rounded),
                    iconSize: 28,
                  ),
                  IconButton(
                    onPressed: () async {
                      if (_audioPlayer == null) return;
                      if (_audioPlayer!.playing) {
                        await _audioPlayer!.pause();
                      } else {
                        await _audioPlayer!.play();
                      }
                    },
                    icon: Icon(_audioPlayer?.playing == true ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    iconSize: 42,
                  ),
                  IconButton(
                    onPressed: () async => _audioPlayer?.seek(const Duration(seconds: 10)),
                    icon: const Icon(Icons.forward_10_rounded),
                    iconSize: 28,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieController == null || _videoController == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('Não foi possível carregar o vídeo.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Chewie(controller: _chewieController!),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}
