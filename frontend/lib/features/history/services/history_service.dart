import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static const String _key = 'stream_downloader_history_v1';

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    return raw;
  }

  Future<void> add(String path) async {
    final items = await load();
    final filtered = items.where((item) => item != path).toList();
    filtered.insert(0, path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, filtered.take(30).toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
