import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:cmcc_manager/setting.dart';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pointycastle/asymmetric/pkcs1.dart';
import 'package:pointycastle/asymmetric/rsa.dart';

final String UA = 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36 EdgA/140.0.0.0';
final Future<String> PASSWORD = AppStorage.getPassword();
final String URL = 'http://192.168.1.1';
Future<String> TOKEN = AppStorage.getToken();
Future<String> SESSION_TOKEN = AppStorage.getSessionToken();
Future<bool> globalDarkMode = AppStorage.getDarkMode();
final GlobalKey<_InfoCardState> cardKey = GlobalKey();
final GlobalKey<_InfoCardState> cardKey1 = GlobalKey();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await I18n.load('zh_cn');
  if (kIsWeb || !Platform.isAndroid) {
    runApp(MaterialApp(home: MyApp()));
  } else {
    runApp(MaterialApp(home: AuthShieldPage()));
  }
}
class AuthShieldPage extends StatefulWidget {
  const AuthShieldPage({super.key});

  @override
  State<AuthShieldPage> createState() => _AuthShieldPageState();
}

class _AuthShieldPageState extends State<AuthShieldPage> {
  final LocalAuthentication auth = LocalAuthentication();
  String authStatus = I18n.t("auth_prompt");

  @override
  void initState() {
    super.initState();
    authenticate();
  }

  Future<void> authenticate() async {
    try {
      bool didAuthenticate = await auth.authenticate(
        localizedReason: I18n.t("auth_prompt"),
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (didAuthenticate) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      } else {
        setState(() {
          authStatus = I18n.t('auth_failed');
        });
      }
    } catch (e) {
      setState(() {
        authStatus = I18n.t("auth_error") + e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: GestureDetector(
          onTap: authenticate,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 100, color: theme.iconTheme.color),
              SizedBox(height: 24),
              Text(I18n.t("auth_title"), style: theme.textTheme.headlineMedium),
              SizedBox(height: 16),
              Text(authStatus, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  int failCount = 0;
  bool isAuthenticating = true;

  @override
  void initState() {
    super.initState();
    startAuthentication();
  }

  Future<void> startAuthentication() async {
    while (failCount < 5) {
      bool success = await simulateAuth();
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MyApp()),
        );
        return;
      } else {
        setState(() {
          failCount++;
        });
      }
    }

    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: Text(I18n.t("auth_failed")),
            content: Text(I18n.t("login_failed_too_many")),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(I18n.t("confirm")),
              ),
            ],
          ),
    ).then((_) => Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AuthShieldPage()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(I18n.t("logging"), style: theme.textTheme.titleMedium),
            SizedBox(height: 12),
            Text("${I18n.t("login_times")}$failCount / 5", style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

Future<bool> simulateAuth() async {
  var dio = Dio();
  var res = (await dio.post(URL)).data.toString();
  var start = res.indexOf("getObj(\"Frm_Logintoken\").value = \"");
  var end = res.indexOf("\"", start + "getObj(\"Frm_Logintoken\").value = \"".length);
  var Frm_Logintoken = res.substring(start + "getObj(\"Frm_Logintoken\").value = \"".length, end);
  var password = encryptPassword(await PASSWORD);
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
    if (data.contains("<title>GM220-S</title>") &&
        !data.contains("function set_online_token()")) {
      return false;
    } else {
      var start1 = data.indexOf("document.cookie = \"USER_LOG_TOKEN=\" + \"");
      var end1 = data.indexOf("\"", start1 + "document.cookie = \"USER_LOG_TOKEN=\" + \"".length);
      AppStorage.setToken("USER_LOG_TOKEN=${data.substring(start1+ "document.cookie = \"USER_LOG_TOKEN=\" + \"".length, end1)}");
      TOKEN = AppStorage.getToken();
      return true;
    }
  } catch (e) {
    return false;
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int currentPage = 0;
  late PageController _pageController;
  bool isDarkMode = false ;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _deliverMode();
  }

  void switchLanguage() async {
    String newLocale = I18n.currentLocale == 'zh_cn' ? 'en_us' : 'zh_cn';
    await I18n.load(newLocale);
    setState(() {});
  }

  void _deliverMode() async {
    isDarkMode = await globalDarkMode;
  }

  void _onPageChanged(int index) {
    setState(() => currentPage = index);
  }

  void _onNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutExpo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkMode
          ? ThemeData.dark().copyWith(
        cardTheme: CardTheme(
          color: Colors.grey[850],
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        scaffoldBackgroundColor: Colors.black,
      )
          : ThemeData.light().copyWith(
        cardTheme: CardTheme(
          color: Color.fromARGB(255, 255, 255, 255),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text(I18n.t('cmcc_gm220_s')),
          actions: [
            //IconButton(
            //  icon: Icon(Icons.language),
            //  tooltip: I18n.t('language'),
            //  onPressed: switchLanguage,
            //),
            IconButton(
              icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              tooltip: I18n.t('dark_mode'),
              onPressed: () => setState(() {
                isDarkMode = !isDarkMode;
                AppStorage.setDarkMode(isDarkMode);
              }),
            ),
          ],
          backgroundColor: isDarkMode
              ? Color.from(alpha: 80, red: 200, green: 200, blue: 200)
              : Color.from(alpha: 220, red: 150, green: 150, blue: 150),
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: [
            buildFiberPage(),
            buildGatewayPage(),
            buildDevicesPage(),
            buildSettingPage()
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentPage,
          onTap: _onNavTapped,
          selectedItemColor: isDarkMode ? Colors.white : Colors.blueAccent,
          unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.black54,
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.wifi),
              label: I18n.t('fiber_broadband'),

            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.router),
              label: I18n.t('local_info'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.devices),
              label: I18n.t('terminal_devices'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: I18n.t("setting")),
          ],
        ),
      ),
    );
  }

  Widget buildFiberPage() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        InfoCard(
          key: cardKey,
          icon: Icons.network_check,
          title: "${I18n.t('optical_network_status')}  \n↑--/s ↓--/s",
          initialFields: [
            FieldItem(label: I18n.t('tx_power'), value: "--", icon: Icons.light_mode),
            FieldItem(label: I18n.t('rx_power'), value: "--", icon: Icons.light_mode_outlined),
            FieldItem(label: I18n.t('working_voltage'), value: "--", icon: Icons.bolt),
            FieldItem(label: I18n.t('working_current'), value: "--", icon: Icons.change_history),
            FieldItem(label: I18n.t('working_temperature'), value: "--", icon: Icons.device_thermostat),
            FieldItem(label: I18n.t('authentication_status'), value: "--", icon: Icons.fingerprint),
          ],
        ),
        InfoCard(
          key: cardKey1,
          icon: Icons.public,
          title: I18n.t('network_service_status'),
          singleLinePerField: false,
          initialFields: [
            FieldItem(label: "${I18n.t("services")} 1", value: "互联网 拨号上网 正常", icon: Icons.rss_feed),
            FieldItem(label: "IP", value: "10.246.15.12", icon: Icons.language),
            FieldItem(label: "DNS1", value: "211.138.30.66", icon: Icons.dns),
            FieldItem(label: "DNS2", value: "211.138.24.66", icon: Icons.dns),

            FieldItem(label: "${I18n.t("services")} 2", value: "中国移动宽带管理中心 自动获取 正常", icon: Icons.rss_feed),
            FieldItem(label: "IP", value: "100.213.210.134", icon: Icons.language),
            FieldItem(label: "DNS1", value: "211.138.30.66", icon: Icons.dns),
            FieldItem(label: "DNS2", value: "211.138.24.66", icon: Icons.dns),
          ],
        )
      ],
    );
  }

  Color _getUsageColor(double value) {
    if (value < 50) return Colors.green;
    if (value < 80) return Colors.orange;
    return Colors.red;
  }

  Widget buildGatewayPage() {
    var cpuUsage = 59;

    var portStatus = {true};
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        buildBigCard(Icons.info_outline, I18n.t('local_info'),
            "${I18n.t('device_model')}: GM220-S\n${I18n.t(
                'uptime')}: 237小时\n${I18n.t(
                'mac_address')}: 64-58-AD-E0-FA-E8"),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          margin: const EdgeInsets.all(2),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HardwareStatusCard(cpuUsage: 59, ramUsage: 20),

                const SizedBox(height: 16),

                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: portStatus.map((port) => Column(
                    children: [
                      Icon(Icons.usb, color: port? Colors.green : Colors.grey),
                      Text(port.toString(), style: const TextStyle(fontSize: 12)),
                    ],
                  )).toList(),
                ),
              ],
            ),
          ),
        )


      ],
    );
  }

  Widget buildDevicesPage() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        buildDeviceCard(
          icon: Icons.tablet_mac,
          name: I18n.t('huawei_tablet'),
          mac: "24:69:8E:8A:2C:A0",
          ip: "192.168.1.2",
          speedUp: "上行：1381kbps",
          speedDown: "下行：7588kbps",
          externalAccess: true,
          storageAccess: false,
          context: context,
        ),
      ],
    );
  }

  Widget buildSettingPage() {
    return ListView(
      children: [

      ],
    );
  }

  Widget buildBigCard(IconData icon, String title, String content, {double size = 48}) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: size, color: Colors.blueAccent),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(content),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget buildDeviceCard({
    required BuildContext context,
    required IconData icon,
    required String name,
    required String mac,
    required String ip,
    required String speedUp,
    required String speedDown,
    required bool externalAccess,
    required bool storageAccess,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Card(
      elevation: 6,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 48, color: primaryColor),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  Text("MAC: $mac"),
                  Text("IP: $ip"),
                  Text(speedUp),
                  Text(speedDown),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    Text(I18n.t('external_access')),
                    Switch(
                      value: externalAccess,
                      onChanged: (_) {},
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(I18n.t('storage_access')),
                    Switch(
                      value: storageAccess,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

}
class InfoCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool singleLinePerField;
  final List<FieldItem> initialFields;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.initialFields,
    this.singleLinePerField = false,
  });

  @override
  State<InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<InfoCard> {
  late List<FieldItem> fields;

  @override
  void initState() {
    super.initState();
    fields = widget.initialFields;
  }

  void updateFields(List<FieldItem> newFields) {
    setState(() => fields = newFields);
  }

  @override
  Widget build(BuildContext context) {
    final double fieldWidth = (MediaQuery.of(context).size.width - 64) / 2;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, size: 36, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: fields.map((field) {
                return SizedBox(
                  width: fieldWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (field.icon != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(field.icon, size: 22, color: Colors.grey[700]),
                        ),
                      if (field.icon != null) const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(field.label,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(field.value,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class FieldItem {
  final String label;
  final String value;
  final IconData? icon;

  FieldItem({required this.label, required this.value, this.icon});
}

class HardwareStatusCard extends StatefulWidget {
  final double cpuUsage;
  final double ramUsage;

  const HardwareStatusCard({
    super.key,
    required this.cpuUsage,
    required this.ramUsage,
  });

  @override
  State<StatefulWidget> createState() => _HardwareStatusCardState();
}

class _HardwareStatusCardState extends State<HardwareStatusCard> {
  @override
  void initState() {
    super.initState();
  }

  Color _getUsageColor(double value) {
    if (value < 50) return Colors.green;
    if (value < 80) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.memory, color: Colors.blueAccent, size: 45,),
              const SizedBox(width: 8),
              const Text("性能概览",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Column(
              mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const SizedBox(width: 14,),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value:  widget.cpuUsage / 100,
                          strokeWidth: 16,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getUsageColor(widget.cpuUsage),
                          ),
                          backgroundColor: Colors.grey[300],
                        ),
                      ),
                      Text("CPU\n${widget.cpuUsage.toInt()}%",
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30,),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CircularProgressIndicator(
                        value: widget.ramUsage / 100,
                        strokeWidth: 26,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getUsageColor(widget.ramUsage),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text("Memory", style: const TextStyle(fontSize: 15)),
                      Text("${widget.cpuUsage.toInt()}%",
                        style: const TextStyle(fontSize: 15)),
                    ],
                  )
                ],
              )
            ]
          ),
        ],
      ),
    );
  }
}

class TempleUserInfo {
  late String sendLightPower;
  late String receiveLightPower;
  late String workVoltage;
  late String workCorrect;
  late String temperature;
  late String verificationStatus;

  TempleUserInfo();
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

Future<TempleUserInfo> getTempleUserInfo(Map<String, dynamic> translations) async {
  var option = BaseOptions(
    headers: {
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Encoding": "gzip, deflate",
      "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6,pt-BR;q=0.5,pt;q=0.4",
      "Cache-Control": "no-cache",
      "Connection": "keep-alive",
      "Cookie": await TOKEN,
      "Host": "192.168.1.1",
      "Pragma": "no-cache",
      "Referer": "http://192.168.1.1/web/cmcc/gch/main.gch",
      "Upgrade-Insecure-Requests": "1",
      "User-Agent": UA
    }
  );
  var dio = Dio(option);
  var res = (await dio.get("$URL/web/cmcc/gch/template_user.gch")).data;
  var templeInfo = TempleUserInfo();
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
          case '0':
            templeInfo.verificationStatus = translations["loid_state_initial"];
            break;
          case '1':
            templeInfo.verificationStatus = translations["loid_state_success"];
            break;
          case '2':
            templeInfo.verificationStatus = translations["loid_state_not_exist"];
            break;
          case '3':
            templeInfo.verificationStatus = translations["loid_state_password_error"];
            break;
          case '4':
            templeInfo.verificationStatus = translations["loid_state_conflict"];
            break;
          default:
            templeInfo.verificationStatus = "";
            break;
        }
        break;
      case 'LosInfo':
        info = value == "1";
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
  templeInfo.workVoltage = getStrings(res, 'name="Frm_Volt">', '</td>');
  templeInfo.temperature = getStrings(res, 'name="Frm_Temp">', '</td>');
  AppStorage.setSessionToken(getStrings(res, 'var session_token = "', '"'));
  SESSION_TOKEN = AppStorage.getSessionToken();

  return templeInfo;
}

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
          "User-Agent": UA,
          "DNT": "1",
          "Content-Type": "text/plain;charset=UTF-8",
          "Accept": "*/*",
          "Origin": "http://192.168.1.1",
          "Referer": "http://192.168.1.1/web/cmcc/gch/template_user.gch",
          "Accept-Encoding": "gzip, deflate",
          "Accept-Language": "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7",
          "Cookie": await TOKEN
        }),
      );

      if (response.statusCode == 302) {
        await _loginAndRetry(_fetchLightData);
        return;
      }

      final data = response.data;
      print(data);
    } catch (e) {
      print("Gateway Info Error: $e");
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
          "User-Agent": UA,
          "DNT": "1",
          "Content-Type": "text/plain;charset=UTF-8",
          "Accept": "*/*",
          "Origin": "http://192.168.1.1",
          "Referer": "http://192.168.1.1/web/cmcc/gch/template_user.gch",
          "Accept-Encoding": "gzip, deflate",
          "Accept-Language": "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7",
          "Cookie": await TOKEN
        })
      );
      if (response.statusCode == 302) {
        await _loginAndRetry(_fetchHeavyData);
        return;
      }
      final data = response.data;
      print(data);
    } catch (e) {
      print("Terminal Info Error: $e");
    }
  }

  Future<void> _loginAndRetry(Function retry) async {
    await simulateAuth();
  }
}

Future<String> getItemInfo(int item) async {
  return (await Dio().post("$URL/web/cmcc/gch/status_info_t.gch",
    options: Options(headers: {
      "Host": "192.168.1.1",
      "Connection": "keep-alive",
      "Content-Length": "6",
      "X-Requested-With": "XMLHttpRequest",
      "User-Agent": UA,
      "Accept": "*/*",
      "DNT": "1",
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      "Origin": "http://192.168.1.1",
      "Referer": "http://192.168.1.1/web/cmcc/gch/template_user.gch",
      "Accept-Encoding": "gzip, deflate",
      "Accept-Language": "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7",
      "Cookie": await TOKEN
    }), data: {
        "item": item
  })).data;
}

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
