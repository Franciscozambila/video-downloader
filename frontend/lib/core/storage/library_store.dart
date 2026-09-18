import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/library_item.dart';

class LibraryStore {
  LibraryStore._();

  static final LibraryStore instance = LibraryStore._();

  static const String _libraryKey = 'library_items';
  static const String _historyKey = 'history_items';

  Future<List<LibraryItem>> getLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_libraryKey) ?? const [];
    return raw
        .map((e) => LibraryItem.fromJson(jsonDecode(e)))
        .where((item) => item.path.isNotEmpty)
        .toList();
  }

  Future<void> saveLibrary(List<LibraryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final values = items.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_libraryKey, values);
  }

  Future<void> addItem(LibraryItem item) async {
    final items = await getLibrary();
    final exists = items.any((element) => element.id == item.id || element.path == item.path);
    if (!exists) {
      items.insert(0, item);
      await saveLibrary(items);
    }
  }

  Future<void> updateItem(LibraryItem item) async {
    final items = await getLibrary();
    final index = items.indexWhere((element) => element.id == item.id);
    if (index >= 0) {
      items[index] = item;
      await saveLibrary(items);
    }
  }

  Future<void> removeItem(String id) async {
    final items = await getLibrary();
    final filtered = items.where((item) => item.id != id).toList();
    await saveLibrary(filtered);
  }

  Future<List<LibraryItem>> getFavorites() async {
    final items = await getLibrary();
    return items.where((item) => item.favorite).toList();
  }

  Future<List<LibraryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? const [];
    return history
        .map((e) => LibraryItem.fromJson(jsonDecode(e)))
        .toList();
  }

  Future<void> addHistory(LibraryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? const [];
    final values = history.where((entry) {
      final decoded = jsonDecode(entry);
      return decoded['id'] != item.id;
    }).toList();
    values.insert(0, jsonEncode(item.toJson()));
    await prefs.setStringList(_historyKey, values.take(20).toList());
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<Directory> getDownloadsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${appDir.path}/downloads');
    if (!downloadsDir.existsSync()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir;
  }
}
