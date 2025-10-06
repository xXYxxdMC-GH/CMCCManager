import 'package:cmcc_manager/global.dart';
import 'package:flutter/material.dart';

import '../../core/setting.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final oldController = TextEditingController();
  final newController = TextEditingController();
  bool verified = false;

  void verifyOldPassword() {
    if (oldController.text == password) {
      setState(() => verified = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("旧密码错误")),
      );
    }
  }

  void saveNewPassword() async {
    await AppStorage.setPassword(newController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("密码已更新")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("更改密码")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: oldController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "当前密码"),
            ),
            const SizedBox(height: 20),
            if (verified)
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "新密码"),
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: verified ? saveNewPassword : verifyOldPassword,
              child: Text(verified ? "保存新密码" : "验证当前密码"),
            ),
          ],
        ),
      ),
    );
  }
}