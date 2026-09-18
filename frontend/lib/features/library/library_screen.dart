import 'package:flutter/material.dart';

import '../../core/player/playback_session.dart';
import '../library/services/library_service.dart';
import '../player/professional_player_screen.dart';
import 'models/library_entry.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final LibraryService _libraryService = LibraryService();
  final List<LibraryEntry> _entries = <LibraryEntry>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final downloadsDir = await _libraryService.getDownloadsDirectory();
    final entries = await _libraryService.scanDirectory(downloadsDir);
    if (!mounted) return;
    setState(() {
      _entries.clear();
      _entries.addAll(entries);
      _loading = false;
    });
  }

  void _openPlayer(LibraryEntry entry) {
    final queue = _entries.map((item) => item.path).toList();
    final index = queue.indexOf(entry.path);

    PlaybackSession.instance.setCurrentMedia(
      title: entry.title,
      path: entry.path,
      isAudioMedia: entry.mediaType == 'audio',
      queueItems: queue,
      index: index >= 0 ? index : 0,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfessionalPlayerScreen(
          title: entry.title,
          path: entry.path,
          isAudio: entry.mediaType == 'audio',
          queue: queue,
          initialIndex: index >= 0 ? index : 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioCount = _entries.where((entry) => entry.mediaType == 'audio').length;
    final videoCount = _entries.where((entry) => entry.mediaType == 'video').length;
    final favoritesCount = _entries.where((entry) => entry.favorite).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Biblioteca'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEntries,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    leading: const Icon(Icons.video_library_rounded),
                    title: const Text('Vídeos'),
                    subtitle: Text('$videoCount itens'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.music_note_rounded),
                    title: const Text('Músicas'),
                    subtitle: Text('$audioCount itens'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.favorite_rounded),
                    title: const Text('Favoritos'),
                    subtitle: Text('$favoritesCount favoritos'),
                  ),
                  const SizedBox(height: 12),
                  if (_entries.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Nenhum arquivo local encontrado na pasta de downloads.'),
                      ),
                    )
                  else
                    ..._entries.map(
                      (entry) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            entry.mediaType == 'audio' ? Icons.music_note_rounded : Icons.videocam_rounded,
                          ),
                          title: Text(entry.title),
                          subtitle: Text(entry.mediaType == 'audio' ? 'Áudio local' : 'Vídeo local'),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_arrow_rounded),
                            onPressed: () => _openPlayer(entry),
                          ),
                          onTap: () => _openPlayer(entry),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
