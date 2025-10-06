import 'package:cmcc_manager/ui/page/pattern_lock_set_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../core/logger.dart';
import '../../core/setting.dart';
import '../../core/translate.dart';
import '../widget/item_widget.dart';
import '../widget/other_widget.dart';
import 'change_password_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _usernameController;
  final FocusNode _focusNode = FocusNode();
  String username = "";
  bool autoLogin = false;

  bool bioEnabled = false;
  bool twoFactorEnabled = false;

  @override
  void initState() {
    _deliverInfo();
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        AppStorage.setUsername(_usernameController.text.trim());
      }
    });
  }

  void _deliverInfo() async {
    bioEnabled = await AppStorage.getBiometricEnabled();
    twoFactorEnabled = await AppStorage.get2FA();
    username = await AppStorage.getUsername();
    _usernameController = TextEditingController(text: username);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsSection(
            icon: Icons.person,
            title: I18n.t('section_user_settings'),
            children: [
              SettingsItem(
                icon: Icons.account_circle,
                label: I18n.t('label_username'),
                subtitle: I18n.t('subtitle_username'),
                trailing: SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _usernameController,
                    focusNode: _focusNode,
                    onChanged: (v) => setState(()  {
                      username = v;
                    }),
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                    decoration: InputDecoration(
                      hintText: I18n.t('hint_enter_username'),
                      hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              SettingsItem(
                icon: Icons.lock,
                label: I18n.t('label_change_password'),
                subtitle: I18n.t('subtitle_change_password'),
                trailing: IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: theme.iconTheme.color),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordPage()));
                  },
                ),
              ),
            ],
          ),

          SettingsSection(
            icon: Icons.settings,
            title: I18n.t('section_app_settings'),
            children: [
              SettingsItem(
                icon: Icons.article,
                label: I18n.t('label_log_record'),
                subtitle: I18n.t('subtitle_log_record'),
                trailing: IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: theme.iconTheme.color,),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LogViewer())),
                ),
              ),
              SettingsItem(
                icon: Icons.fingerprint,
                label: I18n.t('label_biometric_auth'),
                subtitle: I18n.t('subtitle_biometric_auth'),
                trailing: Switch(
                  value: bioEnabled,
                  onChanged: (v) async {
                    setState(() => bioEnabled = v);
                    await AppStorage.setBiometricEnabled(v);
                  },
                ),
              ),
              SettingsItem(
                icon: Icons.verified_user,
                label: I18n.t('label_two_factor_switch'),
                subtitle: I18n.t('subtitle_two_factor_switch'),
                trailing: Switch(
                  value: twoFactorEnabled,
                  onChanged: (v) async {
                    setState(() => twoFactorEnabled = v);
                    await AppStorage.set2FA(v);
                  },
                ),
              ),
              SettingsItem(
                icon: Icons.grid_on,
                label: I18n.t('label_pattern_password'),
                subtitle: I18n.t('subtitle_pattern_password'),
                trailing: IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: theme.iconTheme.color),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PatternLockSetupPage()));
                  },
                ),
              ),
            ],
          ),

          SettingsSection(
            icon: Icons.info,
            title: I18n.t('section_about'),
            children: [
              SettingsItem(
                icon: Icons.tag,
                label: I18n.t('label_version'),
                subtitle: "v1.0.0",
                trailing: const SizedBox.shrink(),
              ),
              SettingsItem(
                icon: Icons.warning,
                label: I18n.t('label_disclaimer'),
                subtitle: I18n.t('subtitle_disclaimer'),
                trailing: const SizedBox.shrink(),
              ),
              SettingsItem(
                icon: Icons.person_pin,
                label: I18n.t('label_author_github'),
                subtitle: I18n.t('subtitle_author_github'),
                trailing: IconButton(
                  icon: Icon(Icons.open_in_new, color: theme.iconTheme.color),
                  onPressed: () => launchUrlString("https://github.com/xXYxxdMC-GH"),
                ),
              ),
              SettingsItem(
                icon: Icons.code,
                label: I18n.t('label_project_repo'),
                subtitle: I18n.t('subtitle_project_repo'),
                trailing: IconButton(
                  icon: Icon(Icons.open_in_new, color: theme.iconTheme.color),
                  onPressed: () => launchUrlString("https://github.com/xXYxxdMC-GH/CMCCManager"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}