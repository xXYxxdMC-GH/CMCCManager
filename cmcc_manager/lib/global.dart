import 'dart:async';

import 'package:cmcc_manager/ui/widget/info_widget.dart';
import 'package:cmcc_manager/utils/network_utils.dart';
import 'package:cmcc_manager/utils/string_html_util.dart';
import 'package:dio/dio.dart';

import 'core/logger.dart';

const String ua =
    'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36 EdgA/140.0.0.0';
const String url = 'http://192.168.1.1';

String password = "";
String gi1 = "";
String gi2 = "";
String deviceIfo = "";

bool isDarkMode = false;
late AppLogger logger;

List<NetworkInterfaceInfo> interfaceInfo = [];
List<int> patter = [];

String token = "";
String sessionToken = "";

class DevicePoller {
  final Duration shortInterval = const Duration(seconds: 1);
  final Duration longInterval = const Duration(seconds: 5);

  Timer? _shortTimer;
  Timer? _longTimer;

  void start() {
    _shortTimer = Timer.periodic(shortInterval, (_) => _fetchLightData());
    _longTimer = Timer.periodic(longInterval, (_) => _fetchHeavyData());
  }

  void stop() {
    _shortTimer?.cancel();
    _longTimer?.cancel();
  }

  Future<void> _fetchLightData() async {
    try {
      final response = await Dio().post(
        "http://192.168.1.1/web/cmcc/gch/status_bandwidth_gch.gch",
        options: Options(headers: {
          "Host": "192.168.1.1",
          "Connection": "keep-alive",
          "Content-Length": "0",
          "User-Agent": ua,
          "DNT": "1",
          "Content-Type": "text/plain;charset=UTF-8",
          "Accept": "*/*",
          "Origin": "http://192.168.1.1",
          "Referer": "http://192.168.1.1/web/cmcc/gch/template_user.gch",
          "Accept-Encoding": "gzip, deflate",
          "Accept-Language": "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7",
          "Cookie": token
        }),
      );

      if (response.statusCode == 302) {
        await _loginAndRetry(_fetchLightData);
        return;
      }

      final data = response.data;
      gi1 = getStrings(data, "<ajax_response_xml_root><BandwidthRx>", "</");
      gi2 = getStrings(data, "</BandwidthRx><BandwidthTx>", "</");
    } catch (e) {
      logger.log("Gateway Info Error: $e", level: LogLevel.error);
    }
  }

  Future<void> _fetchHeavyData() async {
    try {
      final response = await Dio().post(
          "http://192.168.1.1/web/cmcc/gch/status_terminal_info_gch.gch",
          options: Options(headers: {
            "Host": "192.168.1.1",
            "Connection": "keep-alive",
            "Content-Length": "0",
            "User-Agent": ua,
            "DNT": "1",
            "Content-Type": "text/plain;charset=UTF-8",
            "Accept": "*/*",
            "Origin": "http://192.168.1.1",
            "Referer": "http://192.168.1.1/web/cmcc/gch/template_user.gch",
            "Accept-Encoding": "gzip, deflate",
            "Accept-Language": "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7",
            "Cookie": token
          })
      );
      if (response.statusCode == 302) {
        await _loginAndRetry(_fetchHeavyData);
        return;
      }
      deviceIfo = response.data;
    } catch (e) {
      logger.log("Terminal Info Error: $e", level: LogLevel.error);
    }
  }

  Future<void> _loginAndRetry(Function retry) async {
    await simulateAuth();
  }
}
