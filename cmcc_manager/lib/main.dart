import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:cmcc_manager/setting.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pattern_lock/pattern_lock.dart';
import 'package:pointycastle/asymmetric/pkcs1.dart';
import 'package:pointycastle/asymmetric/rsa.dart';

final String UA = 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36 EdgA/140.0.0.0';
String PASSWORD = "";
final String URL = 'http://192.168.1.1';
Future<String> TOKEN = AppStorage.getToken();
Future<String> SESSION_TOKEN = AppStorage.getSessionToken();
bool isDarkMode = false;
final GlobalKey<_InfoCardState> cardKey = GlobalKey();
final GlobalKey<_InfoCardState> cardKey1 = GlobalKey();
String gi1 = "";
String gi2 = "";
List<NetworkInterfaceInfo> interfaceInfo = [];
List<int> patter = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await I18n.load('zh_cn');
  isDarkMode = await AppStorage.getDarkMode();
  PASSWORD = await AppStorage.getPassword();
  patter = await AppStorage.getPattern() ?? [5];
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
      if (didAuthenticate && !(await AppStorage.get2FA())) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => LoginPage(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: Duration(milliseconds: 400),
          ),
        );
      } else if (await AppStorage.get2FA()) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => PatternUnlockPage(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: Duration(milliseconds: 400),
          ),
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
    final theme = isDarkMode ? ThemeData.dark() : ThemeData.light();
    return Scaffold(
      backgroundColor: theme.canvasColor,
      body: Center(
        child: GestureDetector(
          onTap: authenticate,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 100, color: theme.iconTheme.color),
              SizedBox(height: 24),
              Text(I18n.t("auth_title"), style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 24, fontWeight: FontWeight.bold), ),
              SizedBox(height: 16),
              Text(authStatus, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class PatternUnlockPage extends StatefulWidget {
  const PatternUnlockPage({super.key});

  @override
  State<PatternUnlockPage> createState() => _PatternUnlockPageState();
}

class _PatternUnlockPageState extends State<PatternUnlockPage> {
  final List<int> _correctPattern = patter;
  String _status = '请绘制解锁图案';

  void _onPatternCompleted(List<int> input) {
    final isMatch = input.join() == _correctPattern.join();
    setState(() {
      _status = isMatch ? '解锁成功' : '图案错误';
    });

    if (isMatch) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => LoginPage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = isDarkMode ? ThemeData.dark() : ThemeData.light();

    return Scaffold(
      backgroundColor: theme.canvasColor,
      body: Center(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 100, color: theme.iconTheme.color),
              const SizedBox(height: 24),
              Text(
                '图案解锁',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              Text(_status, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 32),
              SizedBox(
                height: 300,
                child: PatternLock(
                  selectedColor: Colors.blueAccent,
                  notSelectedColor: Colors.white,
                  dimension: 3,
                  relativePadding: 0.4,
                  showInput: true,
                  onInputComplete: _onPatternCompleted,
                ),
              ),
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
  int error = 1;

  @override
  void initState() {
    super.initState();
    startAuthentication();
  }

  Future<void> startAuthentication() async {
    while (failCount < 5 && (error == -1 || error == 1)) {
      int success = await simulateAuth();
      switch (success) {
        case -1:
          setState(() {
            failCount++;
          });
          break;
        case 0:
          error = 1;
          setState(() {
            failCount++;
          });
          break;
        case 1:
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => MyApp(),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: Duration(milliseconds: 400),
            ),
          );
          break;
        case 2:
          error = 2;
          setState(() {
            failCount++;
          });
          break;
      }
    }

    if (error == 0) {
      final TextEditingController _controller = TextEditingController();
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("重新设置密码"),
          content: TextField(
            controller: _controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "新密码",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("取消"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPassword = _controller.text.trim();
                if (newPassword.isNotEmpty) {
                  await AppStorage.setPassword(newPassword);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("密码已更新")),
                  );
                }
              },
              child: const Text("确认"),
            ),
          ],
        ),
      );
    } else if (error != 1) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              I18n.t("auth_failed"),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            content: Text(
              error == 2
                  ? "有其他用户正在配置，请稍后再尝试。"
                  : "出现未知错误",
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  I18n.t("confirm"),
                  style: TextStyle(
                    color: isDarkMode ? Colors.blue[200] : Colors.blue,
                  ),
                ),
              ),
            ],
          );
          },
      ).then((_) => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthShieldPage()),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = isDarkMode ? ThemeData.dark() : ThemeData.light();
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

Future<int> simulateAuth() async {
  var dio = Dio(BaseOptions(connectTimeout: Duration(seconds: 5), receiveTimeout: Duration(seconds: 5)));
  var res = (await dio.post(URL)).data.toString();
  var start = res.indexOf("getObj(\"Frm_Logintoken\").value = \"");
  if (start == -1) {
    return -1;
  }
  var end = res.indexOf("\"", start + "getObj(\"Frm_Logintoken\").value = \"".length);
  if (end == -1) {
    return -1;
  }
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
      return 0;
    } else if (data.contains("其他用户正在配置")) {
      return 2;
    } else {
      var start1 = data.indexOf("document.cookie = \"USER_LOG_TOKEN=\" + \"");
      var end1 = data.indexOf("\"", start1 + "document.cookie = \"USER_LOG_TOKEN=\" + \"".length);
      AppStorage.setToken("USER_LOG_TOKEN=${data.substring(start1+ "document.cookie = \"USER_LOG_TOKEN=\" + \"".length, end1)}");
      TOKEN = AppStorage.getToken();
      return 1;
    }
  } catch (e) {
    return -1;
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
  final poller = DevicePoller();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    poller.start();
  }

  @override
  void dispose() {
    poller.stop();
    super.dispose();
  }

  void switchLanguage() async {
    String newLocale = I18n.currentLocale == 'zh_cn' ? 'en_us' : 'zh_cn';
    await I18n.load(newLocale);
    setState(() {});
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
        ).data,
        scaffoldBackgroundColor: Colors.black,
      )
          : ThemeData.light().copyWith(
        cardTheme: CardTheme(
          color: Color.fromARGB(255, 255, 255, 255),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ).data,
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
              ? Color.fromARGB(200, 112, 112, 112)
              : Color.fromARGB(255, 255, 255, 255),
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: [
            FiberPage(cardKey: cardKey, cardKey1: cardKey1),
            GatewayPage(),
            buildDevicesPage()
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

  Widget buildDevicesPage() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        DeviceInfoCard(
          icon: Icons.tablet_mac,
          title: I18n.t('huawei_tablet'),
          subtitle: "192.168.1.2",
          initialExternalAccess: true,
          initialStorageAccess: false,
          fields: [
            DeviceField(label: 'MAC 地址', value: '24:69:8E:8A:2C:A0', icon: Icons.memory),
            DeviceField(label: '上行速度', value: '1381 kbps', icon: Icons.upload),
            DeviceField(label: '下行速度', value: '7588 kbps', icon: Icons.download),
          ],
        )
      ],
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
    final theme = isDarkMode ? ThemeData.dark() : ThemeData.light();
    final primaryColor = theme.colorScheme.primary;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 48, color: primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text("MAC: $mac", style: theme.textTheme.bodySmall),
                  Text("IP: $ip", style: theme.textTheme.bodySmall),
                  Text("↑ $speedUp", style: theme.textTheme.bodySmall),
                  Text("↓ $speedDown", style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              children: [
                _buildSwitchRow(context, I18n.t('external_access'), externalAccess),
                _buildSwitchRow(context, I18n.t('storage_access'), storageAccess),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow(BuildContext context, String label, bool value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Switch(value: value, onChanged: (_) {}),
      ],
    );
  }
}

class FiberPage extends StatefulWidget {
  final Key cardKey;
  final Key cardKey1;

  const FiberPage({
    required this.cardKey,
    required this.cardKey1,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _FiberPageState();
}

class _FiberPageState extends State<FiberPage> with AutomaticKeepAliveClientMixin {
  late final Timer timer;
  late final Timer timer2;
  TempleUserInfo info = TempleUserInfo();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    _deliverInfo();
    timer = Timer.periodic(Duration(seconds: 2), (_) {
      setState(() {});
    });
    timer2 = Timer.periodic(Duration(seconds: 10), (_) {
      setState(() {
        _deliverInfo();
      });
    });
    super.initState();
  }

  void _deliverInfo() async {
    info = await getTempleUserInfo();
  }

  @override
  void dispose() {
    timer.cancel();
    timer2.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InfoCard(
          key: cardKey,
          icon: Icons.network_check,
          title: I18n.t('optical_network_status'),
          subTitle: "↑${formatBandwidth(gi1)}bp/s ↓${formatBandwidth(gi2)}bp/s",
          initialFields: [
            FieldItem(label: I18n.t('tx_power'), value: info.sendLightPower, icon: Icons.light_mode),
            FieldItem(label: I18n.t('rx_power'), value: info.receiveLightPower, icon: Icons.light_mode_outlined),
            FieldItem(label: I18n.t('working_voltage'), value: info.workVoltage, icon: Icons.bolt),
            FieldItem(label: I18n.t('working_current'), value: info.workCorrect, icon: Icons.change_history),
            FieldItem(label: I18n.t('working_temperature'), value: info.temperature, icon: Icons.device_thermostat),
            FieldItem(label: I18n.t('authentication_status'), value: info.verificationStatus, icon: Icons.fingerprint),
          ],
        ),
        InfoCard(
          key: cardKey1,
          icon: Icons.public,
          title: I18n.t('network_service_status'),
          singleLinePerField: false,
          initialFields: buildFieldItems(),
        ),
      ],
    );
  }
}

class GatewayPage extends StatefulWidget {
  const GatewayPage({super.key});

  @override
  State<StatefulWidget> createState() => _GatewayPageState();
}

class _GatewayPageState extends State<GatewayPage> with AutomaticKeepAliveClientMixin {
  late final Timer timer;
  Map<String, dynamic> snapshot = {
    'cpuUsage': 0.0,
    'ramUsage': 0.0,
    'deviceModel': '--',
    'firmwareVersion': '--',
    'uptime': '--',
    'macAddress': '--',
    'deviceId': '--',
    'ports': {
      '光口': false,
      '网口1': false,
      '网口2': false,
      '网口3': false,
      '网口4': false,
      'USB1': false,
    },
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    _deliverInfo();
    timer = Timer.periodic(Duration(seconds: 3), (_) {
      setState(() {
        _deliverInfo();
      });
    });
    super.initState();
  }

  void _deliverInfo() async {
    snapshot = extractDeviceSnapshot(await getItemInfo(1));
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    List<bool> ethStatusList = [];
    for (String key in (snapshot['ports'] as Map<String, dynamic>).keys) {
      if (key.contains("网口")) {
        ethStatusList.add(snapshot['ports'][key]);
      }
    }
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          margin: const EdgeInsets.all(8),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: HardwareStatusCard(
                cpuUsage: snapshot['cpuUsage'] as double,
                ramUsage: snapshot['ramUsage'] as double,
                sfpConnected: snapshot['ports']['光口'],
                ethStatus: ethStatusList,
                usbConnected: snapshot['ports']['USB1'],
              )
          ),
        ),
        InfoCard(
          icon: Icons.info_outline,
          title: I18n.t('local_info'),
          initialFields: [
            FieldItem(
              label: I18n.t('device_model'),
              value: snapshot['deviceModel'],
              icon: Icons.devices_other,
            ),
            FieldItem(
              label: I18n.t('firmware_version'),
              value: snapshot['firmwareVersion'],
              icon: Icons.system_update_alt,
            ),
            FieldItem(
              label: I18n.t('uptime'),
              value: snapshot['uptime'],
              icon: Icons.access_time,
            ),
            FieldItem(
              label: I18n.t('mac_address'),
              value: snapshot['macAddress'],
              icon: Icons.memory,
            ),
            FieldItem(
              label: I18n.t('device_id'),
              value: snapshot['deviceId'],
              icon: Icons.qr_code,
            )
          ],
        ),
      ],
    );
  }
}

List<FieldItem> buildFieldItems() {
  final fields = <FieldItem>[];

  for (int i = 0; i < interfaceInfo.length; i++) {
    final iface = interfaceInfo[i];
    fields.add(FieldItem(
      label: "${I18n.t("services")} ${i + 1}",
      value: "${iface.name} ${iface.connectionType} ${iface.status}",
      icon: Icons.rss_feed,
    ));
    fields.add(FieldItem(label: "IP", value: iface.ip, icon: Icons.language));
    fields.add(FieldItem(label: "DNS1", value: iface.dns1, icon: Icons.dns));
    fields.add(FieldItem(label: "DNS2", value: iface.dns2, icon: Icons.dns));
  }

  return fields;
}

class InfoCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool singleLinePerField;
  final List<FieldItem> initialFields;
  final String subTitle;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    this.subTitle = "",
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
  void didUpdateWidget(covariant InfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFields != oldWidget.initialFields) {
      setState(() {
        fields = widget.initialFields;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double fieldWidth = (MediaQuery.of(context).size.width - 100) / 2;

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
                Icon(widget.icon, size: 40, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.subTitle != "") Text(
                        widget.subTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
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

class DeviceField {
  final String label;
  final String value;
  final IconData? icon;

  DeviceField({required this.label, required this.value, this.icon});
}

class DeviceInfoCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<DeviceField> fields;
  final bool initialExternalAccess;
  final bool initialStorageAccess;

  const DeviceInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.initialExternalAccess,
    required this.initialStorageAccess,
  });

  @override
  State<DeviceInfoCard> createState() => _DeviceInfoCardState();
}

class _DeviceInfoCardState extends State<DeviceInfoCard> {
  late bool externalAccess;
  late bool storageAccess;

  @override
  void initState() {
    super.initState();
    externalAccess = widget.initialExternalAccess;
    storageAccess = widget.initialStorageAccess;
  }

  void toggleExternal(bool value) {
    setState(() => externalAccess = value);
    // TODO: 发送更新请求或保存状态
  }

  void toggleStorage(bool value) {
    setState(() => storageAccess = value);
    // TODO: 发送更新请求或保存状态
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double fieldWidth = (MediaQuery.of(context).size.width - 24) / 2;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(widget.icon, size: 36, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20
                          )),
                      if (widget.subtitle.isNotEmpty)
                        Text(widget.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            )),
                    ],
                  ),
                ),
                const SizedBox(width: 18,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("↑${widget.fields[1].value}",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          )),
                      Text("↓${widget.fields[2].value}",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: fieldWidth,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.fields.first.icon != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(widget.fields.first.icon, size: 20, color: theme.iconTheme.color?.withOpacity(0.6)),
                    ),
                  if (widget.fields.first.icon != null) const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.fields.first.label,
                            style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
                        const SizedBox(height: 4),
                        Text(widget.fields.first.value,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSwitchRow(context, '外网访问', externalAccess, toggleExternal),
                _buildSwitchRow(context, '存储访问', storageAccess, toggleStorage),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow(BuildContext context, String label, bool value, ValueChanged<bool> onChanged) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(width: 8),
        Switch(value: value, onChanged: onChanged),
      ],
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
  final bool sfpConnected;
  final List<bool> ethStatus;
  final bool usbConnected;


  const HardwareStatusCard({
    super.key,
    required this.cpuUsage,
    required this.ramUsage,
    required this.sfpConnected,
    required this.ethStatus,
    required this.usbConnected,
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

  Widget _buildCircularIndicator({
    required String label,
    required double value,
    required double size,
    required double strokeWidth,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value / 100),
      curve: Curves.easeOutBack,
      duration: const Duration(milliseconds: 600),
      builder: (context, animatedValue, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size + 20,
              height: size - 10,
              child: RoundedCircularIndicator(
                value: animatedValue,
                size: size,
                strokeWidth: strokeWidth,
                backgroundColor: isDarkMode ? Colors.black38 : Colors.grey[300]!,
                foregroundColor: AlwaysStoppedAnimation<Color>(_getUsageColor(value)).value,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 15)),
                Text("${value.toInt()}%", style: const TextStyle(fontSize: 15)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPortStatus({
    required IconData icon,
    required String label,
    required bool isConnected,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isConnected ? Colors.green : Colors.grey),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
              fontSize: 14,
              color: isConnected ? Colors.green : Colors.grey,
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.memory, color: Colors.blueAccent, size: 45),
              SizedBox(width: 8),
              Text("性能概览",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCircularIndicator(
                label: "CPU",
                value: widget.cpuUsage,
                size: 80,
                strokeWidth: 16,
              ),
              _buildCircularIndicator(
                label: "Memory",
                value: widget.ramUsage,
                size: 100,
                strokeWidth: 26,
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text("接口状态",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPortStatus(
                icon: Icons.wifi_tethering,
                label: "光口",
                isConnected: widget.sfpConnected,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  for (int i = 0; i < widget.ethStatus.length; i++)
                    _buildPortStatus(
                      icon: Icons.settings_ethernet,
                      label: "网口 ${i + 1}",
                      isConnected: widget.ethStatus[i],
                    ),
                ],
              ),
              const SizedBox(height: 6),
              _buildPortStatus(
                icon: Icons.usb,
                label: "USB",
                isConnected: widget.usbConnected,
              ),
            ],
          ),
        ],
      ),
    );
  }
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

class TempleUserInfo {
  String sendLightPower = "--";
  String receiveLightPower = "--";
  String workVoltage = "--";
  String workCorrect = "--";
  String temperature = "--";
  String verificationStatus = "--";

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

Future<TempleUserInfo> getTempleUserInfo() async {
  var option = BaseOptions(
    headers: {
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Encoding": "gzip, deflate",
      "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6,pt-BR;q=0.5,pt;q=0.4",
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
  SESSION_TOKEN = AppStorage.getSessionToken();

  interfaceInfo = parseNetworkInterfaces(res);

  return templeInfo;
}

class NetworkInterfaceInfo {
  final String name;
  final String connectionType;
  final String status;
  final String ip;
  final String dns1;
  final String dns2;

  NetworkInterfaceInfo({
    required this.name,
    required this.connectionType,
    required this.status,
    required this.ip,
    required this.dns1,
    required this.dns2,
  });

  @override
  String toString() {
    return '$name [$connectionType] - $status\nIP: $ip\nDNS1: $dns1\nDNS2: $dns2';
  }
}

List<NetworkInterfaceInfo> parseNetworkInterfaces(String raw) {
  final interfaceRegex = RegExp(
    r'<td[^>]*>\s*(\d+)\s*</td>\s*' + // index
        r'<td[^>]*>\s*(.*?)\s*</td>\s*' + // name
        r'<td[^>]*>\s*(.*?)\s*</td>\s*' + // connection type
        r'<td[^>]*>\s*(.*?)\s*</td>\s*' + // status
        r'<td[^>]*>\s*IP:(.*?)\s*</td>',  // IP
    multiLine: true,
  );

  final matches = interfaceRegex.allMatches(raw).toList();

  final result = <NetworkInterfaceInfo>[];

  final dnsMatches = RegExp(r'DNS\d:([\d\.]+)').allMatches(raw).toList();

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
      gi1 = getStrings(data, "<ajax_response_xml_root><BandwidthRx>", "</");
      gi2 = getStrings(data, "</BandwidthRx><BandwidthTx>", "</");
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

String _decodeHtmlEntities(String encoded) {
  return encoded.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
    final code = int.parse(match.group(1)!);
    return String.fromCharCode(code);
  });
}

class RoundedCircularIndicator extends StatelessWidget {
  final double value; // 0.0 ~ 1.0
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final Color foregroundColor;

  const RoundedCircularIndicator({
    super.key,
    required this.value,
    required this.size,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RoundedCircularPainter(
          value: value,
          strokeWidth: strokeWidth,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        ),
      ),
    );
  }
}

class _RoundedCircularPainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final Color backgroundColor;
  final Color foregroundColor;

  _RoundedCircularPainter({
    required this.value,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final foregroundPaint = Paint()
      ..color = foregroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final pi = 3.1415926;

    final sweepAngle = 2 * pi * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
