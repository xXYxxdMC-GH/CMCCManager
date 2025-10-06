import 'package:flutter/material.dart';

class FieldItem {
  final String label;
  final String value;
  final IconData? icon;

  FieldItem({required this.label, required this.value, this.icon});
}

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;

  const SettingsItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: theme.iconTheme.color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 16, color: theme.iconTheme.color)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(subtitle!, style: TextStyle(fontSize: 12, color: theme.iconTheme.color)),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}