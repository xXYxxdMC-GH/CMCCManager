import 'package:flutter/material.dart';
import 'package:pattern_lock/pattern_lock.dart';

import '../../core/translate.dart';
import '../../global.dart';
import 'login_page.dart';

class PatternUnlockPage extends StatefulWidget {
  const PatternUnlockPage({super.key});

  @override
  State<PatternUnlockPage> createState() => _PatternUnlockPageState();
}

class _PatternUnlockPageState extends State<PatternUnlockPage> {
  final List<int> _correctPattern = patter;
  String _status = I18n.t('pattern_unlock_prompt');

  void _onPatternCompleted(List<int> input) {
    final isMatch = input.join() == _correctPattern.join();
    setState(() {
      _status = isMatch
          ? I18n.t('pattern_unlock_success')
          : I18n.t('pattern_unlock_failed');
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
                I18n.t('pattern_unlock_title'),
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