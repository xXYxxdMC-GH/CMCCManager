import 'package:cmcc_manager/global.dart';
import 'package:cmcc_manager/utils/string_html_util.dart';
import 'package:dio/dio.dart';

import '../core/setting.dart';
import '../core/translate.dart';
import '../ui/widget/info_widget.dart';

Future<int> simulateAuth() async {
  var dio = Dio(BaseOptions(connectTimeout: Duration(seconds: 5), receiveTimeout: Duration(seconds: 5)));
  var res = (await dio.post(url)).data.toString();
  var start = res.indexOf("getObj(\"Frm_Logintoken\").value = \"");
  if (start == -1) {
    return -1;
  }
  var end = res.indexOf("\"", start + "getObj(\"Frm_Logintoken\").value = \"".length);
  if (end == -1) {
    return -1;
  }
  var frmLogintoken = res.substring(start + "getObj(\"Frm_Logintoken\").value = \"".length, end);
  var encryptedPassword = encryptPassword(password);
  var usr = encryptPassword('');
  var formData = {
    'action': 'login',
    'Frm_Logintoken': frmLogintoken,
    'username': 'user',
    'logincode': encryptedPassword,
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
          'user-agent': ua,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
          'Referer': 'http://192.168.1.1/',
          'Accept-Encoding': 'gzip, deflate',
          'Accept-Language': 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7'
        },
      ),
    );

    var data = response.data.toString();
    if (data.contains("<title>GM220-S</title>") &&
        !data.contains("function set_online_token()")) {
      return 0;
    } else if (data.contains("其他用户正在配置")) {
      return 2;
    } else {
      var start1 = data.indexOf("document.cookie = \"USER_LOG_TOKEN=\" + \"");
      var end1 = data.indexOf("\"", start1 + "document.cookie = \"USER_LOG_TOKEN=\" + \"".length);
      AppStorage.setToken("USER_LOG_TOKEN=${data.substring(start1+ "document.cookie = \"USER_LOG_TOKEN=\" + \"".length, end1)}");
      token = await AppStorage.getToken();
      return 1;
    }
  } catch (e) {
    return -1;
  }
}

Future<List<DeviceInfo>> extractDevices() async {
  var dio = Dio();
  var xml = (await dio.post("$url/web/cmcc/gch/status_terminal_info_gch.gch", options: Options(
      headers: {
        "Accept": "*/*",
        "Accept-Encoding": "gzip, deflate",
        "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6,pt-BR;q=0.5,pt;q=0.4",
        "Connection": "keep-alive",
        "Content-Length": "0",
        "Content-Type": "text/plain;charset=UTF-8",
        "Cookie": token,
        "Host": "192.168.1.1",
        "Origin": "http://192.168.1.1",
        "Pragma": "no-cache",
        "Referer": "http://192.168.1.1/web/cmcc/gch/template_user.gch",
        "User-Agent": ua
      }
  ))).data;

  final deviceList = <DeviceInfo>[];

  final infonumMatch = RegExp(r'<infonum>(\d+)</infonum>').firstMatch(xml);
  final count = int.parse(infonumMatch?.group(1) ?? '0');

  for (int i = 0; i < count; i++) {
    final name = RegExp('<devName$i>(.*?)</devName$i>').firstMatch(xml)?.group(1) ?? '';
    final ip = RegExp('<ipAddr$i>(.*?)</ipAddr$i>').firstMatch(xml)?.group(1) ?? '';
    final mac = RegExp('<macAddr$i>(.*?)</macAddr$i>').firstMatch(xml)?.group(1) ?? '';
    final upstream = int.parse(RegExp('<strus$i>(.*?)</strus$i>').firstMatch(xml)?.group(1) ?? '0');
    final downstream = int.parse(RegExp('<strds$i>(.*?)</strds$i>').firstMatch(xml)?.group(1) ?? '0');
    final inet = int.parse(RegExp('<InetAcc_dev$i>(.*?)</InetAcc_dev$i>').firstMatch(xml)?.group(1) ?? '1');
    final stg = int.parse(RegExp('<StgAcc_dev$i>(.*?)</StgAcc_dev$i>').firstMatch(xml)?.group(1) ?? '0');

    deviceList.add(DeviceInfo(
      name: name,
      ip: ip,
      mac: mac,
      upstream: upstream,
      downstream: downstream,
      internetAccess: inet == 2,
      storageAccess: stg == 1,
    ));
  }

  return deviceList;
}

Future<void> switchPermission(String mac, bool permission, int option, bool internetAccess, bool storageAccess) async {
  var data = {
    "Mac": mac,
    "InetAcc_dev": option == 1 ? (internetAccess ? 2 : 1) : (internetAccess ? 1 : 2), // 1 is close, 2 is open
    "StgAcc_dev": option == 0 ? (storageAccess ? 1 : 0) : (storageAccess ? 0 : 1), // 0 is close, 1 is open
    "IF_ACTION": "new",
    "IF_INDEX": "-1",
    "_SESSION_TOKEN_USER": sessionToken,
  };
  await Dio().post("$url/web/cmcc/gch/status_term_blktype_gch.gch", options: Options(
      headers: {
        "Accept": "*/*",
        "Accept-Encoding": "gzip, deflate",
        "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6,pt-BR;q=0.5,pt;q=0.4",
        "Connection": "keep-alive",
        "Content-Length": data.length,
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "Cookie": token,
        "Host": "192.168.1.1",
        "Origin": "http://192.168.1.1",
        "Referer": "http://192.168.1.1/web/cmcc/gch/template_user.gch",
        "User-Agent": ua,
        "X-Requested-With": "XMLHttpRequest",
      }
  ), data: data);
}

Future<TempleUserInfo> getTempleUserInfo() async {
  var option = BaseOptions(
      headers: {
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        "Accept-Encoding": "gzip, deflate",
        "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6,pt-BR;q=0.5,pt;q=0.4",
        "Connection": "keep-alive",
        "Cookie": token,
        "Host": "192.168.1.1",
        "Pragma": "no-cache",
        "Referer": "http://192.168.1.1/web/cmcc/gch/main.gch",
        "Upgrade-Insecure-Requests": "1",
        "User-Agent": ua
      }
  );
  var dio = Dio(option);
  var res = (await dio.get("$url/web/cmcc/gch/template_user.gch")).data;
  if (res.toString().contains("页面超时，请重新登录。")) {
    await simulateAuth();
    return TempleUserInfo();
  }
  var templeInfo = TempleUserInfo();
  RegExp regExp = RegExp(r'var\s+(LosInfo|RxPower|TxPower|Current)\s*=\s*"([^"]+)"');
  Iterable<Match> matches = regExp.allMatches(res);
  var info = true;

  for (var match in matches) {
    String name = match.group(1)!;
    String value = match.group(2)!;

    switch (name) {
      case 'LosInfo':
        info = (value != "1");
        break;
      case 'RxPower':
        templeInfo.receiveLightPower = info ? "${(double.parse(value) / 10000).toStringAsFixed(1)}dBm" : "--";
        break;
      case 'TxPower':
        templeInfo.sendLightPower = info ? "${(double.parse(value) / 10000).toStringAsFixed(1)}dBm" : "--";
        break;
      case 'Current':
        templeInfo.workCorrect = info ? "${(int.parse(value) / 1000).toStringAsFixed(1)}mA" : "--";
        break;
    }
  }

  switch (getStrings(res, 'Transfer_meaning(\'LoidState\',\'', '\')')) {
    case '5':
      break;
    case '0':
      templeInfo.verificationStatus = I18n.t("loid_state_initial");
      break;
    case '1':
      templeInfo.verificationStatus = I18n.t("loid_state_success");
      break;
    case '2':
      templeInfo.verificationStatus = I18n.t("loid_state_not_exist");
      break;
    case '3':
      templeInfo.verificationStatus = I18n.t("loid_state_password_error");
      break;
    case '4':
      templeInfo.verificationStatus = I18n.t("loid_state_conflict");
      break;
    default:
      templeInfo.verificationStatus = "";
      break;
  }
  templeInfo.workVoltage = getStrings(res, 'name="Frm_Volt">', '</td>');
  templeInfo.temperature = getStrings(res, 'name="Frm_Temp">', '</td>');
  AppStorage.setSessionToken(getStrings(res, 'var session_token = "', '"'));
  sessionToken = await AppStorage.getSessionToken();

  interfaceInfo = parseNetworkInterfaces(res);

  return templeInfo;
}