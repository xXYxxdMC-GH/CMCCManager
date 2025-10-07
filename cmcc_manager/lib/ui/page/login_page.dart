import 'package:flutter/material.dart';

import '../../core/setting.dart';
import '../../core/translate.dart';
import '../../global.dart';
import '../../main.dart';
import '../../utils/network_utils.dart';
import 'auth_shield_page.dart';

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
          error = -1;
          break;
        case 0:
          error = 0;
          setState(() {
            failCount++;
          });
          break;
        case 1:
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => CMCCManager(),
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
      final TextEditingController controller = TextEditingController();
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(I18n.t('reset_password_title')),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(
              labelText: I18n.t('new_password'),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(I18n.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPassword = controller.text.trim();
                if (newPassword.isNotEmpty) {
                  await AppStorage.setPassword(newPassword);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(I18n.t('password_updated'))),
                    );
                  }
                }
              },
              child: Text(I18n.t('confirm')),
            ),
          ],
        ),
      );
    } else if (error != 1) {
      if (!mounted) return;
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
                  ? I18n.t('other_user_configuring')
                  : I18n.t('unknown_error'),
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
      ).then((_) =>
      {
        if (mounted)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AuthShieldPage()),
          )});
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

