import 'package:cmcc_manager/core/logger.dart';
import 'package:cmcc_manager/core/setting.dart';
import 'package:cmcc_manager/ui/page/auth_shield_page.dart';
import 'package:cmcc_manager/ui/page/device_operate_page.dart';
import 'package:cmcc_manager/ui/page/fiber_page.dart';
import 'package:cmcc_manager/ui/page/gateway_page.dart';
import 'package:cmcc_manager/ui/page/login_page.dart';
import 'package:cmcc_manager/ui/page/setting_page.dart';
import 'package:cmcc_manager/ui/widget/card_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/translate.dart';
import 'global.dart';

final GlobalKey<InfoCardState> cardKey = GlobalKey();
final GlobalKey<InfoCardState> cardKey1 = GlobalKey();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await I18n.load(await AppStorage.getLanguage());
  isDarkMode = await AppStorage.getDarkMode();
  password = await AppStorage.getPassword();
  patter = await AppStorage.getPattern() ?? [5];
  token = await AppStorage.getToken();
  sessionToken = await AppStorage.getSessionToken();
  logger = await AppLogger.getInstance();
  await logger.clearLogs();
  if (await AppStorage.getBiometricEnabled() && !kIsWeb) {
    runApp(MaterialApp(home: AuthShieldPage()));
  } else {
    runApp(MaterialApp(home: LoginPage()));
  }
}

class CMCCManager extends StatefulWidget {
  const CMCCManager({super.key});

  @override
  State<CMCCManager> createState() => _CMCCManagerState();
}

final devicePageKey = GlobalKey<DeviceOperatePageState>();

class _CMCCManagerState extends State<CMCCManager> {
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
    await AppStorage.setLanguage(newLocale);
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

  Color getAppBarColor(bool isDarkMode, int currentPage) {
    if (currentPage == 3) {
      return isDarkMode ? Colors.black : Colors.white;
    } else {
      return isDarkMode
          ? const Color.fromARGB(200, 112, 112, 112)
          : const Color.fromARGB(255, 255, 255, 255);
    }
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
            IconButton(
              icon: Icon(Icons.language),
              tooltip: I18n.t('language'),
              onPressed: switchLanguage,
            ),
            IconButton(
              icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              tooltip: I18n.t('dark_mode'),
              onPressed: () => setState(() {
                isDarkMode = !isDarkMode;
                AppStorage.setDarkMode(isDarkMode);
              }),
            ),
          ],
          backgroundColor: getAppBarColor(isDarkMode, currentPage),
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: [
            FiberPage(cardKey: cardKey, cardKey1: cardKey1),
            GatewayPage(),
            DeviceOperatePage(key: devicePageKey,),
            SettingsPage()
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
                label: I18n.t('setting')),
          ],
        ),
      ),
    );
  }
}