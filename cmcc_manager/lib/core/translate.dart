import 'dart:convert';

import 'package:flutter/services.dart';

class I18n {
  static Map<String, String> _translations = {};
  static String _currentLocale = 'zh_cn';

  static Future<void> load(String locale) async {
    _currentLocale = locale;
    final String jsonStr = await rootBundle.loadString('assets/lang/$locale.json');
    final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);
    _translations = jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }

  static String t(String key) {
    return _translations[key] ?? key;
  }

  static String get currentLocale => _currentLocale;
}