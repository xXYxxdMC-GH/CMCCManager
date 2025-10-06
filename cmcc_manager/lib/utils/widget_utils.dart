import 'package:flutter/material.dart';

import '../core/translate.dart';
import '../global.dart';
import '../ui/widget/item_widget.dart';

List<FieldItem> buildFieldItems() {
  final fields = <FieldItem>[];

  for (int i = 0; i < interfaceInfo.length; i++) {
    final iface = interfaceInfo[i];
    fields.add(FieldItem(
      label: "${I18n.t("services")} ${i + 1}",
      value: "${iface.name} ${iface.connectionType} ${iface.status}",
      icon: Icons.rss_feed,
    ));
    fields.add(FieldItem(label: "IP", value: iface.ip, icon: Icons.language));
    fields.add(FieldItem(label: "DNS1", value: iface.dns1, icon: Icons.dns));
    fields.add(FieldItem(label: "DNS2", value: iface.dns2, icon: Icons.dns));
  }

  return fields;
}