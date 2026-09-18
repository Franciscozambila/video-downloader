import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PlaylistItem {
  final String id;
  final String title;
  final List<String> paths;
  final DateTime createdAt;

  const PlaylistItem({
    required this.id,
    required this.title,
    required this.paths,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'paths': paths,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PlaylistItem.fromJson(Map<String, dynamic> json) => PlaylistItem(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Playlist',
        paths: (json['paths'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}

class PlaylistsService {
  static const String _key = 'stream_downloader_playlists_v1';

  Future<List<PlaylistItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    return raw
        .map((item) => PlaylistItem.fromJson(jsonDecode(item)))
        .where((playlist) => playlist.id.isNotEmpty)
        .toList();
  }

  Future<void> save(List<PlaylistItem> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      playlists.map((playlist) => jsonEncode(playlist.toJson())).toList(),
    );
  }

  Future<void> add(String title, List<String> paths) async {
    final playlists = await load();
    final newPlaylist = PlaylistItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      paths: paths,
      createdAt: DateTime.now(),
    );
    playlists.add(newPlaylist);
    await save(playlists);
  }

  Future<void> addTrackToPlaylist(String playlistId, String path) async {
    final playlists = await load();
    final index = playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index < 0) return;
    final target = playlists[index];
    final paths = [...target.paths, path];
    playlists[index] = PlaylistItem(
      id: target.id,
      title: target.title,
      paths: paths.toSet().toList(),
      createdAt: target.createdAt,
    );
    await save(playlists);
  }
}
