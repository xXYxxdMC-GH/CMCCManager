import 'package:cmcc_manager/ui/page/pattern_lock_set_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../core/logger.dart';
import '../../core/setting.dart';
import '../widget/item_widget.dart';
import '../widget/other_widget.dart';
import 'change_password_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String username = "";
  String password = "";
  bool autoLogin = false;

  bool bioEnabled = false;
  bool twoFactorEnabled = false;

  @override
  void initState() {
    _deliverInfo();
    super.initState();
  }

  void _deliverInfo() async {
    bioEnabled = await AppStorage.getBiometricEnabled();
    twoFactorEnabled = await AppStorage.get2FA();
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
            title: "用户设置",
            children: [
              SettingsItem(
                icon: Icons.account_circle,
                label: "名称",
                subtitle: "用于登录后台",
                trailing: SizedBox(
                  width: 160,
                  child: TextField(
                    controller: TextEditingController(text: username),
                    onChanged: (v) => setState(() => username = v),
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                    decoration: const InputDecoration(
                      hintText: "请输入名称",
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              SettingsItem(
                icon: Icons.lock,
                label: "更改密码",
                subtitle: "需要验证当前密码",
                trailing: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordPage()));
                  },
                ),
              ),
            ],
          ),

          SettingsSection(
            icon: Icons.settings,
            title: "APP 设置",
            children: [
              SettingsItem(
                icon: Icons.article,
                label: "日志记录",
                subtitle: "记录关键操作与异常信息",
                trailing: IconButton(onPressed: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => LogViewer())),
                    icon: Icon(Icons.arrow_forward_ios)),
              ),
              SettingsItem(
                icon: Icons.fingerprint,
                label: "生物验证",
                subtitle: "支持指纹或面容识别",
                trailing: Switch(
                  value: bioEnabled,
                  onChanged: (v) => setState(() => bioEnabled = v),
                ),
              ),
              SettingsItem(
                icon: Icons.verified_user,
                label: "二次验证开关",
                subtitle: "启用后进入敏感区域需验证",
                trailing: Switch(
                  value: twoFactorEnabled,
                  onChanged: (v) => setState(() => twoFactorEnabled = v),
                ),
              ),
              SettingsItem(
                icon: Icons.grid_on,
                label: "二次验证密码",
                subtitle: "用于图案验证，默认点击中间点可解锁",
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
            title: "关于",
            children: [
              // 版本信息
              SettingsItem(
                icon: Icons.tag,
                label: "版本号",
                subtitle: "v1.0.0",
                trailing: const SizedBox.shrink(),
              ),

              // 免责声明
              SettingsItem(
                icon: Icons.warning,
                label: "免责声明",
                subtitle: "本应用仅供学习与交流使用",
                trailing: const SizedBox.shrink(),
              ),

              // GitHub 主页
              SettingsItem(
                icon: Icons.person_pin,
                label: "作者 GitHub",
                subtitle: "查看作者主页",
                trailing: IconButton(
                  icon: Icon(Icons.open_in_new, color: theme.iconTheme.color),
                  onPressed: () => launchUrlString("https://github.com/xXYxxdMC-GH"),
                ),
              ),

              // 项目仓库
              SettingsItem(
                icon: Icons.code,
                label: "项目仓库",
                subtitle: "查看源代码与更新",
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