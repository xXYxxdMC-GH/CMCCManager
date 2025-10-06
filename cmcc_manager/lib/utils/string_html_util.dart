import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:dio/dio.dart';
import 'package:pointycastle/asymmetric/pkcs1.dart';
import 'package:pointycastle/asymmetric/rsa.dart';

import '../global.dart';
import '../ui/widget/info_widget.dart';

String encryptPassword(String plainText) {
  final publicKeyPem = '''
-----BEGIN PUBLIC KEY-----
MIGdMA0GCSqGSIb3DQEBAQUAA4GLADCBhwKBgQDrQunyHq5EGzlc6GFZ+LJrvnZ5+Jd8ArqgR6xvuBTNtqbPDz1NfnMTuusny1etUUY3UUPckEH2SVClSxYZTuy9T5OXsUP+9CimcZ7ft/WuabcOkvw/WoAkzJwOySVUNxRDGhDTS59tZhQ11C42WIpdD+vDELH4OcQ7XrlLA/mHbwIBAw==
-----END PUBLIC KEY-----
''';

  RSAPublicKey publicKey = CryptoUtils.rsaPublicKeyFromPem(publicKeyPem);

  final encryptor = PKCS1Encoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

  final inputBytes = Uint8List.fromList(utf8.encode(plainText));
  final encryptedBytes = encryptor.process(inputBytes);

  final hex = encryptedBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  final hexBytes = Uint8List.fromList([
    for (int i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16)
  ]);
  return base64Encode(hexBytes);
}

String getStrings(String res, String marker, String end) {
  int start = res.indexOf(marker);
  if (start != -1) {
    int valueStart = start + marker.length;
    int valueEnd = res.indexOf(end, valueStart);
    if (valueEnd != -1) {
      String value = res.substring(valueStart, valueEnd);
      return value;
    }
  }
  return "--";
}

Future<String> getItemInfo(int item) async {
  return (await Dio().post("$url/web/cmcc/gch/status_info_t.gch",
      options: Options(headers: {
        "Host": "192.168.1.1",
        "Connection": "keep-alive",
        "Content-Length": "6",
        "X-Requested-With": "XMLHttpRequest",
        "User-Agent": ua,
        "Accept": "*/*",
        "DNT": "1",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "Origin": "http://192.168.1.1",
        "Referer": "http://192.168.1.1/web/cmcc/gch/template_user.gch",
        "Accept-Encoding": "gzip, deflate",
        "Accept-Language": "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7",
        "Cookie": token
      }), data: {
        "item": item
      })).data;
}

String formatBandwidth(String bpsS) {
  try {
    final bpsB = num.parse(bpsS);
    double bps = bpsB * 8 / 1024;
    if (bps < 800) {
      return "${bps.toStringAsFixed(2)} K";
    } else if (bps < 1000 * 1000) {
      return "${(bps / 1000).toStringAsFixed(2)} M";
    } else if (bps < 1000 * 1000 * 1000) {
      return "${(bps / 1000000).toStringAsFixed(2)} G";
    } else {
      return "${(bps / 1000000000).toStringAsFixed(2)} T";
    }
  } catch (e) {
    return "--";
  }
}

String _decodeHtmlEntities(String encoded) {
  return encoded.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
    final code = int.parse(match.group(1)!);
    return String.fromCharCode(code);
  });
}

List<NetworkInterfaceInfo> parseNetworkInterfaces(String raw) {
  final interfaceRegex = RegExp(
    r'<td[^>]*>\s*(\d+)\s*</td>\s*'  // index
    r'<td[^>]*>\s*(.*?)\s*</td>\s*'  // name
    r'<td[^>]*>\s*(.*?)\s*</td>\s*'  // connection type
    r'<td[^>]*>\s*(.*?)\s*</td>\s*'  // status
    r'<td[^>]*>\s*IP:(.*?)\s*</td>',  // IP
    multiLine: true,
  );

  final matches = interfaceRegex.allMatches(raw).toList();

  final result = <NetworkInterfaceInfo>[];

  final dnsMatches = RegExp(r'DNS\d:([\d.]+)').allMatches(raw).toList();

  for (int i = 0; i < matches.length; i++) {
    final m = matches[i];
    final dns1 = dnsMatches.length > i * 2 ? dnsMatches[i * 2].group(1)!.trim() : '';
    final dns2 = dnsMatches.length > i * 2 + 1 ? dnsMatches[i * 2 + 1].group(1)!.trim() : '';

    result.add(NetworkInterfaceInfo(
      name: m.group(2)!.trim(),
      connectionType: m.group(3)!.trim(),
      status: m.group(4)!.trim(),
      ip: m.group(5)!.trim(),
      dns1: dns1,
      dns2: dns2,
    ));
  }

  return result;
}

Map<String, dynamic> extractDeviceSnapshot(String rawHtml) {
  final cpuMatch = RegExp(r'<span id="cpuPercent">(\d+)</span>').firstMatch(rawHtml);
  final memMatch = RegExp(r'<span id="memPercent">(\d+)</span>').firstMatch(rawHtml);

  final modelMatch = RegExp(r'id="Frm_ModelName".*?>(.*?)<').firstMatch(rawHtml);
  final versionMatch = RegExp(r'id="SoftwareVer".*?>(.*?)<').firstMatch(rawHtml);
  final uptimeMatch = RegExp(r'id="Frm_Runtime".*?>(.*?)<').firstMatch(rawHtml);
  final macMatch = RegExp(r'id="Frm_IP".*?>(.*?)<').firstMatch(rawHtml);
  final idMatch = RegExp(r'id="Frm_Mac".*?>(.*?)<').firstMatch(rawHtml);

  return {
    'cpuUsage': double.tryParse(cpuMatch?.group(1) ?? '0') ?? 0,
    'ramUsage': double.tryParse(memMatch?.group(1) ?? '0') ?? 0,
    'deviceModel': _decodeHtmlEntities(modelMatch?.group(1) ?? ''),
    'firmwareVersion': _decodeHtmlEntities(versionMatch?.group(1) ?? ''),
    'uptime': _decodeHtmlEntities(uptimeMatch?.group(1) ?? ''),
    'macAddress': _decodeHtmlEntities(macMatch?.group(1) ?? ''),
    'deviceId': _decodeHtmlEntities(idMatch?.group(1) ?? ''),
    'ports': extractPortStatus(rawHtml),
  };
}

Map<String, bool> extractPortStatus(String rawHtml) {
  final matches = RegExp(r'src="/img.*?</font>', dotAll: true).allMatches(rawHtml);
  final result = <String, bool>{};

  for (final match in matches) {
    final block = match.group(0)!;

    final nameMatch = RegExp(r'>([^<>]+)</font>').firstMatch(block);
    final name = nameMatch?.group(1) ?? '未知端口';

    final connected = block.contains('green') || block.contains('blue');

    result[name] = connected;
  }

  return result;
}
