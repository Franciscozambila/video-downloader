import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/library_entry.dart';

class LibraryService {
  static const String _key = 'stream_downloader_library_v1';

  Future<List<LibraryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((item) => LibraryEntry.fromJson(jsonDecode(item)))
        .where((entry) => entry.path.isNotEmpty)
        .toList();
  }

  Future<void> save(List<LibraryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      entries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  Future<void> addEntry(LibraryEntry entry) async {
    final entries = await load();
    final exists = entries.any((current) => current.id == entry.id || current.path == entry.path);
    if (!exists) {
      entries.insert(0, entry);
      await save(entries);
    }
  }

  Future<void> removeEntry(String id) async {
    final entries = await load();
    final filtered = entries.where((entry) => entry.id != id).toList();
    await save(filtered);
  }

  Future<List<LibraryEntry>> scanDirectory(Directory directory) async {
    final result = <LibraryEntry>[];
    if (!directory.existsSync()) return result;

    final supported = <String>{'.mp3', '.m4a', '.wav', '.aac', '.mp4', '.mkv', '.webm', '.mov'};
    for (final file in directory.listSync(recursive: true, followLinks: false)) {
      if (file is File) {
        final ext = file.path.toLowerCase();
        if (supported.any((suffix) => ext.endsWith(suffix))) {
          final mediaType = ext.endsWith('.mp3') ||
                  ext.endsWith('.m4a') ||
                  ext.endsWith('.wav') ||
                  ext.endsWith('.aac')
              ? 'audio'
              : 'video';
          result.add(LibraryEntry(
            id: file.path.hashCode.toString(),
            title: file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'Arquivo local',
            path: file.path,
            mediaType: mediaType,
            createdAt: DateTime.now(),
          ));
        }
      }
    }
    return result;
  }

  Future<Directory> getDownloadsDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${dir.path}/downloads');
    if (!downloadsDir.existsSync()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir;
  }
}
