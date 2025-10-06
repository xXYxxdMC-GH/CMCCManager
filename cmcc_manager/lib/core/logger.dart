import 'dart:io';
import 'dart:convert';
import 'package:cmcc_manager/core/translate.dart';
import 'package:flutter/material.dart';
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

  Future<void> log(String message, {LogLevel level = LogLevel.info}) async {
    final entry = LogEntry(timestamp: DateTime.now(), message: message, level: level);
    final logs = await getLogs();
    logs.add(entry);

    const maxLogs = 500;
    if (logs.length > maxLogs) {
      logs.removeRange(0, logs.length - maxLogs);
    }

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

enum LogLevel { error, warning, info, debug }

class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogLevel level;

  LogEntry({required this.timestamp, required this.message, required this.level});

  @override
  String toString() => "[${timestamp.toIso8601String()}] ${level.name.toUpperCase()} $message";

  Map<String, dynamic> toJson() => {
    "timestamp": timestamp.toIso8601String(),
    "message": message,
    "level": level.name,
  };

  static LogEntry fromJson(Map<String, dynamic> json) => LogEntry(
    timestamp: DateTime.parse(json["timestamp"]),
    message: json["message"],
    level: LogLevel.values.firstWhere((e) => e.name == json["level"]),
  );
}

class LogViewer extends StatefulWidget {
  const LogViewer({super.key});

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  List<LogEntry> logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logger = await AppLogger.getInstance();
    final newLogs = await logger.getLogs();
    setState(() => logs = newLogs);
  }

  Color getLevelColor(BuildContext context, LogLevel level) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (level) {
      case LogLevel.error:
        return isDark ? Colors.red.shade900 : Colors.red.shade100;
      case LogLevel.warning:
        return isDark ? Colors.orange.shade900 : Colors.orange.shade100;
      case LogLevel.info:
        return isDark ? Colors.blue.shade900 : Colors.blue.shade100;
      case LogLevel.debug:
        return isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    }
  }

  String getLevelLabel(LogLevel level) {
    return level.name.toUpperCase();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(I18n.t('log'))),
      body: RefreshIndicator(
        onRefresh: _loadLogs,
        child: ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return ListTile(
              tileColor: getLevelColor(context, log.level),
              title: Text(
                "${getLevelLabel(log.level)}  ${log.message}",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(log.timestamp.toIso8601String()),
            );
          },
        ),
      ),
    );
  }
}

