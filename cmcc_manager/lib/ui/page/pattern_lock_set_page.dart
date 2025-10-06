import 'package:flutter/material.dart';
import 'package:pattern_lock/pattern_lock.dart';

import '../../core/setting.dart';
import '../../core/translate.dart';

class PatternLockSetupPage extends StatefulWidget {
  const PatternLockSetupPage({super.key});

  @override
  State<PatternLockSetupPage> createState() => _PatternLockSetupPageState();
}

class _PatternLockSetupPageState extends State<PatternLockSetupPage> {
  List<int>? pattern;

  void onPatternEntered(List<int> input) async {
    const minPatternLength = 4;

    if (input.length < minPatternLength) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(I18n.t('pattern_too_short'))),
      );
      return;
    }

    setState(() => pattern = input);

    await AppStorage.setPattern(pattern!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text("${I18n.t('pattern_saved')}: ${input.join('-')}")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final patternSize = screenWidth * 0.7;

    return Scaffold(
      appBar: AppBar(title: Text(I18n.t('set_pattern_password'))),
      body: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final patternSize = maxHeight * 0.5;

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_on, size: 48, color: Theme.of(context).iconTheme.color),
                  const SizedBox(height: 16),
                  Text(I18n.t('draw_pattern_prompt'), style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: patternSize,
                    height: patternSize,
                    child: PatternLock(
                      selectedColor: Colors.blueAccent,
                      notSelectedColor: Colors.grey.shade400,
                      dimension: 3,
                      relativePadding: 0.3,
                      showInput: true,
                      onInputComplete: onPatternEntered,
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }

}