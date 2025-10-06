import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isDarkMode", value);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("isDarkMode") ?? false;
  }

  static Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("language", value);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("language") ?? "zh_cn";
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("userToken", token);
  }

  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userToken") ?? '';
  }

  static Future<void> setPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("password", password);
  }

  static Future<String> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("password") ?? 'W5abt#3q';
  }

  static Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("username", username);
  }

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("username") ?? 'user';
  }

  static Future<void> setSessionToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("session_token", token);
  }

  static Future<String> getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("session_token") ?? '';
  }

  static Future<void> set2FA(bool needed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("2fa_authenticate", needed);
  }

  static Future<bool> get2FA() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("2fa_authenticate") ?? false;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("biometric_enabled", enabled);
  }

  static Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("biometric_enabled") ?? true;
  }

  static Future<void> setPattern(List<int> pattern) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('unlock_pattern', pattern.join(','));
  }

  static Future<List<int>?> getPattern() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('unlock_pattern');
    if (raw == null) return [4];
    return raw.split(',').map(int.parse).toList();
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
