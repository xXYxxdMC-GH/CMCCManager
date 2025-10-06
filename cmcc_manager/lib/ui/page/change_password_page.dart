import 'package:flutter/material.dart';

import '../../core/setting.dart';
import '../../core/translate.dart';

enum PasswordState { verifying, verified, failed }

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final oldController = TextEditingController();
  final newController = TextEditingController();
  PasswordState state = PasswordState.verifying;
  String password = "";

  @override
  void initState() {
    super.initState();
    _loadPassword();
  }

  Future<void> _loadPassword() async {
    password = await AppStorage.getPassword();
  }

  void _verifyOldPassword() {
    if (oldController.text == password) {
      setState(() => state = PasswordState.verified);
    } else {
      setState(() => state = PasswordState.failed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(I18n.t('old_password_incorrect'))),
      );
    }
  }

  Future<void> _saveNewPassword() async {
    await AppStorage.setPassword(newController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(I18n.t('password_updated'))),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = state == PasswordState.verified;
    return Scaffold(
      appBar: AppBar(title: Text(I18n.t('change_password'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: oldController,
                obscureText: true,
                decoration: InputDecoration(labelText: I18n.t('current_password')),
                validator: (value) =>
                value == null || value.isEmpty ? I18n.t('auth_prompt') : null,
              ),
              const SizedBox(height: 20),
              if (isVerified)
                TextFormField(
                  controller: newController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: I18n.t('new_password')),
                  validator: (value) =>
                  value == null || value.length < 6 ? I18n.t('pattern_too_short') : null,
                ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: Icon(isVerified ? Icons.save : Icons.lock),
                label: Text(isVerified
                    ? I18n.t('save_new_password')
                    : I18n.t('verify_current_password')),
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    isVerified ? _saveNewPassword() : _verifyOldPassword();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
