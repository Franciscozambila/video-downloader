import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _key = 'stream_downloader_favorites_v1';

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const <String>[];
  }

  Future<void> toggle(String path) async {
    final items = await load();
    final updated = items.contains(path)
        ? items.where((item) => item != path).toList()
        : <String>[...items, path];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated);
  }

  Future<bool> isFavorite(String path) async {
    final items = await load();
    return items.contains(path);
  }
}
