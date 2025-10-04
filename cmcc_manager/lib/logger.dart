import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  static AppLogger? _instance;
  late File _logFile;

  AppLogger._internal();

  static Future<AppLogger> getInstance() async {
    if (_instance == null) {
      _instance = AppLogger._internal();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    _logFile = File('${dir.path}/app_log.json');
    if (!await _logFile.exists()) {
      await _logFile.create(recursive: true);
      await _logFile.writeAsString(jsonEncode([]));
    }
  }

  Future<void> log(String message) async {
    final entry = LogEntry(timestamp: DateTime.now(), message: message);
    final logs = await getLogs();
    logs.add(entry);
    final jsonList = logs.map((e) => e.toJson()).toList();
    await _logFile.writeAsString(jsonEncode(jsonList));
  }

  Future<List<LogEntry>> getLogs() async {
    final content = await _logFile.readAsString();
    final List<dynamic> jsonList = jsonDecode(content);
    return jsonList.map((e) => LogEntry.fromJson(e)).toList();
  }

  Future<void> clearLogs() async {
    await _logFile.writeAsString(jsonEncode([]));
  }

  Future<File> getLogFile() async => _logFile;
}


class LogEntry {
  final DateTime timestamp;
  final String message;

  LogEntry({required this.timestamp, required this.message});

  @override
  String toString() => "[${timestamp.toIso8601String()}] $message";

  Map<String, dynamic> toJson() => {
    "timestamp": timestamp.toIso8601String(),
    "message": message,
  };

  static LogEntry fromJson(Map<String, dynamic> json) => LogEntry(
    timestamp: DateTime.parse(json["timestamp"]),
    message: json["message"],
  );
}
