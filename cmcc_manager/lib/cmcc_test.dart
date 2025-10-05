import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pointycastle/asymmetric/pkcs1.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:basic_utils/basic_utils.dart';

import 'main.dart';

final String UA = 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36 EdgA/140.0.0.0';
final String PASSWORD = 'W5abt#3q';
final String URL = 'http://192.168.1.1';
String TOKEN = "";
String SESSION_TOKEN = "";

void main() async {
  String jsonStr = await File('assets/lang/zh_cn.json').readAsString();
  Map<String, dynamic> translations = jsonDecode(jsonStr);
  var dio = Dio();
  var res = (await dio.post(URL)).data.toString();
  var start = res.indexOf("getObj(\"Frm_Logintoken\").value = \"");
  var end = res.indexOf("\"", start + "getObj(\"Frm_Logintoken\").value = \"".length);
  var Frm_Logintoken = res.substring(start + "getObj(\"Frm_Logintoken\").value = \"".length, end);
  var password = encryptPassword(PASSWORD);
  var usr = encryptPassword('');
  var formData = {
    'action': 'login',
    'Frm_Logintoken': Frm_Logintoken,
    'username': 'user',
    'logincode': password,
    'usr': usr,
    'ieversion': '1'
  };

  try {
    var response = await dio.post(
      'http://192.168.1.1',
      data: formData,
      options: Options(
        headers: {
          'Host': '192.168.1.1',
          'Connection': 'keep-alive',
          'Content-Length': formData.length.toString(),
          'Cache-Control': 'max-age=0',
          'Origin': 'http://192.168.1.1',
          'DNT': '1',
          'Upgrade-Insecure-Requests': '1',
          'Content-Type': 'application/x-www-form-urlencoded',
          'user-agent': UA,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
          'Referer': 'http://192.168.1.1/',
          'Accept-Encoding': 'gzip, deflate',
          'Accept-Language': 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7'
        },
      ),
    );

    var data = response.data.toString();
    if (data.contains("<title>GM220-S</title>") && !data.contains("function set_online_token()")) {
      print('响应结果: ${data.contains("<title>GM220-S</title>")}, 登陆失败');
      print(data);
      return;
    } else print('响应结果: true, 登陆成功');

    var start1 = data.indexOf("document.cookie = \"USER_LOG_TOKEN=\" + \"");
    var end1 = data.indexOf("\"", start1 + "document.cookie = \"USER_LOG_TOKEN=\" + \"".length);
    TOKEN = "USER_LOG_TOKEN=" + data.substring(start1+ "document.cookie = \"USER_LOG_TOKEN=\" + \"".length, end1);

    var header = {
      "Host": "192.168.1.1",
      "Connection": "keep-alive",
      "DNT": "1",
      "Upgrade-Insecure-Requests": "1",
      "User-Agent": "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36 EdgA/140.0.0.0",
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Referer": "http://192.168.1.1/",
      "Accept-Encoding": "gzip, deflate",
      "Accept-Language": "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7",
      "Cookie": TOKEN
    };
    var option = BaseOptions(
      receiveDataWhenStatusError: true,
      responseType: ResponseType.plain,
      headers: header,
    );
    dio = Dio(option);
    var res1 = await dio.get("$URL/web/cmcc/gch/main.gch");
    option.headers["Referer"] = "http://192.168.1.1/web/cmcc/gch/template_user.gch";
    option.headers["Origin"] = "http://192.168.1.1";
    option.headers["Accept"] = "*/*";
    option.headers["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8";
    option.headers["X-Requested-With"] = "XMLHttpRequest";
    option.headers["Content-Length"] = "6";
    var res2 = await dio.post("$URL/web/cmcc/gch/status_info_t.gch",
        data: {
          "item": 1,
        }, options: Options(headers: option.headers));
    var templeInfo = await getTempleUserInfo();
    print(templeInfo.receiveLightPower);
  } catch (e) {
    print('请求失败: $e');
  }
}



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
class TempleUserInfo {
  late String sendLightPower;
  late String receiveLightPower;
  late String workVoltage;
  late String workCorrect;
  late String temperature;
  late String verificationStatus;

  TempleUserInfo();

  // TempleUserInfo(this.sendLightPower, this.receiveLightPower, this.workVoltage, this.workCorrect, this.temperature, this.verificationStatus);

  void refresh(String res, Map<String, dynamic> translations) {
    RegExp regExp = RegExp(r'var\s+(LoidState|LosInfo|RxPower|TxPower|Current)\s*=\s*"([^"]+)"');
    Iterable<Match> matches = regExp.allMatches(res);
    var info = true;

    for (var match in matches) {
      String name = match.group(1)!;
      String value = match.group(2)!;

      switch (name) {
        case 'LoidState':
          switch (value) {
            case '5':
              break;
            case '1':
              verificationStatus = translations["loid_state_initial"];
              break;
            case '1':
              verificationStatus = translations["loid_state_success"];
              break;
            case '2':
              verificationStatus = translations["loid_state_not_exist"];
              break;
            case '3':
              verificationStatus = translations["loid_state_password_error"];
              break;
            case '4':
              verificationStatus = translations["loid_state_conflict"];
              break;
            default:
              verificationStatus = "";
              break;
          }
          break;
        case 'LosInfo':
          info = value == "1";
          break;
        case 'RxPower':
          receiveLightPower = info ? (double.parse(value) / 10000).toStringAsFixed(1) + "dBm" : "--";
          break;
        case 'TxPower':
          sendLightPower = info ? (double.parse(value) / 10000).toStringAsFixed(1) + "dBm" : "--";
          break;
        case 'Current':
          workCorrect = info ? (int.parse(value) / 1000).toStringAsFixed(1) + "mA" : "--";
          break;
      }
    }
    workVoltage = getStrings(res, 'name="Frm_Volt">', '</td>');
    temperature = getStrings(res, 'name="Frm_Temp">', '</td>');
    SESSION_TOKEN = getStrings(res, 'var session_token = "', '"');
  }

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
class DeviceInfoRes {
  
}