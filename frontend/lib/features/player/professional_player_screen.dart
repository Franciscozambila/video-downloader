import 'dart:io';
import 'dart:math' as math;

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

class ProfessionalPlayerScreen extends StatefulWidget {
  final String title;
  final String path;
  final bool isAudio;
  final List<String> queue;
  final int initialIndex;

  const ProfessionalPlayerScreen({
    super.key,
    required this.title,
    required this.path,
    this.isAudio = false,
    this.queue = const [],
    this.initialIndex = 0,
  });

  @override
  State<ProfessionalPlayerScreen> createState() => _ProfessionalPlayerScreenState();
}

class _ProfessionalPlayerScreenState extends State<ProfessionalPlayerScreen> {
  AudioPlayer? _audioPlayer;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  bool _loading = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 0.8;
  double _boost = 1.0;
  bool _shuffle = false;
  String _repeatMode = 'off';

  List<String> _queue = const [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _queue = widget.queue.isNotEmpty ? List<String>.from(widget.queue) : (widget.path.isNotEmpty ? [widget.path] : const []);
    _currentIndex = widget.initialIndex.clamp(0, math.max(0, _queue.length - 1));
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    setState(() => _loading = true);
    try {
      if (widget.path.isEmpty) {
        return;
      }

      if (widget.isAudio) {
        _audioPlayer = AudioPlayer();
        await _audioPlayer!.setFilePath(widget.path);
        _audioPlayer!.positionStream.listen((pos) {
          if (!mounted) return;
          setState(() {
            _position = pos;
            _duration = _audioPlayer?.duration ?? Duration.zero;
          });
        });
        _audioPlayer!.playerStateStream.listen((state) {
          if (!mounted) return;
          setState(() {
            _position = _audioPlayer?.position ?? _position;
            _duration = _audioPlayer?.duration ?? _duration;
          });
        });
      } else {
        _videoController = VideoPlayerController.file(File(widget.path));
        await _videoController!.initialize();
        _videoController!.addListener(() {
          if (!mounted) return;
          setState(() {
            _position = _videoController!.value.position;
            _duration = _videoController!.value.duration;
          });
        });
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false,
          looping: false,
          allowFullScreen: true,
          allowPlaybackSpeedChanging: true,
          showControls: true,
        );
      }
    } catch (_) {
      debugPrint('Player init failed for ${widget.path}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _seekBy(int seconds) {
    final adjusted = Duration(seconds: seconds);

    if (widget.isAudio && _audioPlayer != null) {
      final next = _audioPlayer!.position + adjusted;
      _audioPlayer!.seek(next < Duration.zero ? Duration.zero : next);
      return;
    }

    if (!widget.isAudio && _videoController != null) {
      final next = _videoController!.value.position + adjusted;
      _videoController!.seekTo(next < Duration.zero ? Duration.zero : next);
    }
  }

  Future<void> _togglePlayback() async {
    if (widget.isAudio && _audioPlayer != null) {
      if (_audioPlayer!.playing) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.play();
      }
      setState(() {});
      return;
    }

    if (!widget.isAudio && _videoController != null) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      setState(() {});
    }
  }

  Future<void> _nextTrack() async {
    if (_queue.isEmpty) return;
    if (_repeatMode == 'repeat one') {
      if (widget.isAudio && _audioPlayer != null) {
        await _audioPlayer!.seek(Duration.zero);
      }
      return;
    }

    if (_shuffle) {
      final candidates = List<int>.generate(_queue.length, (index) => index)
        ..remove(_currentIndex);
      if (candidates.isEmpty) {
        _currentIndex = 0;
      } else {
        _currentIndex = candidates[(DateTime.now().millisecondsSinceEpoch % candidates.length)];
      }
    } else {
      if (_repeatMode == 'off' && _currentIndex >= _queue.length - 1) {
        _currentIndex = _queue.length - 1;
      } else {
        _currentIndex = (_currentIndex + 1) % _queue.length;
      }
    }

    await _openQueuePath(_queue[_currentIndex]);
  }

  Future<void> _previousTrack() async {
    if (_queue.isEmpty) return;
    if (_repeatMode == 'repeat one') {
      if (widget.isAudio && _audioPlayer != null) {
        await _audioPlayer!.seek(Duration.zero);
      }
      return;
    }

    if (_shuffle) {
      final candidates = List<int>.generate(_queue.length, (index) => index)
        ..remove(_currentIndex);
      if (candidates.isEmpty) {
        _currentIndex = 0;
      } else {
        _currentIndex = candidates[(DateTime.now().millisecondsSinceEpoch + 1) % candidates.length];
      }
    } else {
      if (_currentIndex == 0) {
        _currentIndex = _queue.isNotEmpty ? _queue.length - 1 : 0;
      } else {
        _currentIndex = _currentIndex - 1;
      }
    }

    await _openQueuePath(_queue[_currentIndex]);
  }

  Future<void> _openQueuePath(String path) async {
    if (path.isEmpty) return;
    if (widget.isAudio) {
      _audioPlayer ??= AudioPlayer();
      await _audioPlayer!.setFilePath(path);
      await _audioPlayer!.play();
      setState(() {});
      return;
    }

    if (_videoController != null) {
      await _videoController!.dispose();
      _chewieController?.dispose();
    }
    _videoController = VideoPlayerController.file(File(path));
    await _videoController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      allowFullScreen: true,
      allowPlaybackSpeedChanging: true,
      showControls: true,
    );
    setState(() {});
  }

  void _setVolume(double value) {
    _volume = value;
    if (_audioPlayer != null) {
      _audioPlayer!.setVolume(value);
    }
    if (_videoController != null) {
      _videoController!.setVolume(value);
    }
    setState(() {});
  }

  void _cycleRepeatMode() {
    setState(() {
      _repeatMode = switch (_repeatMode) {
        'off' => 'repeat all',
        'repeat all' => 'repeat one',
        _ => 'off',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.path.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Nenhuma mídia selecionada para reprodução local.'),
          ),
        ),
      );
    }

    final currentPosition = _position;
    final totalDuration = _duration;

    if (widget.isAudio) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.music_note_rounded, size: 96),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(onPressed: _previousTrack, icon: const Icon(Icons.skip_previous_rounded), iconSize: 32),
                    IconButton(onPressed: () => _seekBy(-10), icon: const Icon(Icons.replay_10_rounded), iconSize: 30),
                    IconButton(onPressed: () => _seekBy(-5), icon: const Icon(Icons.keyboard_double_arrow_left_rounded), iconSize: 30),
                    IconButton(
                      onPressed: _togglePlayback,
                      icon: Icon(_audioPlayer?.playing == true ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      iconSize: 48,
                    ),
                    IconButton(onPressed: () => _seekBy(5), icon: const Icon(Icons.keyboard_double_arrow_right_rounded), iconSize: 30),
                    IconButton(onPressed: () => _seekBy(10), icon: const Icon(Icons.forward_10_rounded), iconSize: 30),
                    IconButton(onPressed: _nextTrack, icon: const Icon(Icons.skip_next_rounded), iconSize: 32),
                  ],
                ),
                const SizedBox(height: 18),
                Slider(
                  value: currentPosition.inMilliseconds.clamp(
                    0,
                    totalDuration.inMilliseconds == 0 ? 0 : totalDuration.inMilliseconds,
                  ).toDouble(),
                  max: totalDuration.inMilliseconds == 0 ? 1 : totalDuration.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    if (_audioPlayer != null) {
                      _audioPlayer!.seek(Duration(milliseconds: value.toInt()));
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(currentPosition)),
                      Text(_formatDuration(totalDuration)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.volume_up_rounded),
                    Expanded(
                      child: Slider(
                        value: _volume,
                        min: 0,
                        max: 1,
                        onChanged: _setVolume,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _shuffle = !_shuffle),
                      icon: Icon(Icons.shuffle_rounded, color: _shuffle ? Colors.green : null),
                    ),
                    IconButton(
                      onPressed: _cycleRepeatMode,
                      icon: Icon(
                        Icons.repeat_rounded,
                        color: _repeatMode == 'off' ? null : Colors.orange,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _boost = _boost < 1.6 ? _boost + 0.2 : 1.0),
                      icon: const Icon(Icons.graphic_eq_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Volume boost: ${_boost.toStringAsFixed(1)}x'),
              ],
            ),
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
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(onPressed: () => _seekBy(-5), icon: const Icon(Icons.replay_5_rounded)),
                  IconButton(onPressed: () => _seekBy(-10), icon: const Icon(Icons.replay_10_rounded)),
                  IconButton(
                    onPressed: _togglePlayback,
                    icon: Icon(_videoController!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  ),
                  IconButton(onPressed: () => _seekBy(5), icon: const Icon(Icons.forward_5_rounded)),
                  IconButton(onPressed: () => _seekBy(10), icon: const Icon(Icons.forward_10_rounded)),
                  IconButton(onPressed: _previousTrack, icon: const Icon(Icons.skip_previous_rounded)),
                  IconButton(onPressed: _nextTrack, icon: const Icon(Icons.skip_next_rounded)),
                  const Spacer(),
                  PopupMenuButton<double>(
                    icon: const Icon(Icons.speed_rounded),
                    onSelected: (value) {
                      if (_videoController != null) {
                        _videoController!.setPlaybackSpeed(value);
                        setState(() {});
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 0.5, child: Text('0.5x')),
                      PopupMenuItem(value: 0.75, child: Text('0.75x')),
                      PopupMenuItem(value: 1.0, child: Text('1x')),
                      PopupMenuItem(value: 1.25, child: Text('1.25x')),
                      PopupMenuItem(value: 1.5, child: Text('1.5x')),
                      PopupMenuItem(value: 1.75, child: Text('1.75x')),
                      PopupMenuItem(value: 2.0, child: Text('2x')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}
