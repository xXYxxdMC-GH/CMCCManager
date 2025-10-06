import 'package:flutter/material.dart';
import 'package:pattern_lock/pattern_lock.dart';

import '../../core/setting.dart';

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
        const SnackBar(content: Text("图案至少包含 4 个点")),
      );
      return;
    }

    setState(() => pattern = input);

    await AppStorage.setPattern(pattern!);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text("图案已保存：${input.join('-')}")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("设置图案密码")),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("请绘制图案密码", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 40),
              SizedBox(
                width: 300,
                height: 300,
                child: PatternLock(
                  selectedColor: Colors.blueAccent,
                  notSelectedColor: Colors.grey.shade400,
                  dimension: 3,
                  relativePadding: 0.3,
                  showInput: true,
                  onInputComplete: onPatternEntered,
                ),
              )
            ],
          ),
        )
    );
  }
}