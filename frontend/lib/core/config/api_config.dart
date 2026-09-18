import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _keyBaseUrl = 'api_base_url';

  static const String defaultBaseUrl = 'http://10.0.2.2:8000';

  static String _currentBaseUrl = defaultBaseUrl;

  static String get baseUrl => _currentBaseUrl;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentBaseUrl = prefs.getString(_keyBaseUrl) ?? defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String newUrl) async {
    final formatted = newUrl.endsWith('/')
        ? newUrl.substring(0, newUrl.length - 1)
        : newUrl;
    _currentBaseUrl = formatted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, formatted);
  }
}
