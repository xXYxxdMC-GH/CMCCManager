import 'package:cmcc_manager/ui/page/login_page.dart';
import 'package:cmcc_manager/ui/page/pattern_unlock_page.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/setting.dart';
import '../../core/translate.dart';
import '../../global.dart';

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
      if (didAuthenticate && !(await AppStorage.get2FA()) && mounted) {
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
      } else if (await AppStorage.get2FA() && mounted) {
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