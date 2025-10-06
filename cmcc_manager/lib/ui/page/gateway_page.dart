import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/translate.dart';
import '../../utils/string_html_util.dart';
import '../widget/card_widget.dart';
import '../widget/item_widget.dart';

class GatewayPage extends StatefulWidget {
  const GatewayPage({super.key});

  @override
  State<StatefulWidget> createState() => _GatewayPageState();
}

class _GatewayPageState extends State<GatewayPage> with AutomaticKeepAliveClientMixin {
  late final Timer timer;
  Map<String, dynamic> snapshot = {
    'cpuUsage': 0.0,
    'ramUsage': 0.0,
    'deviceModel': '--',
    'firmwareVersion': '--',
    'uptime': '--',
    'macAddress': '--',
    'deviceId': '--',
    'ports': {
      'optical': false,
      'ethernet1': false,
      'ethernet2': false,
      'ethernet3': false,
      'ethernet4': false,
      'usb1': false,
    },
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    _deliverInfo();
    timer = Timer.periodic(Duration(seconds: 3), (_) {
      setState(() {
        _deliverInfo();
      });
    });
    super.initState();
  }

  void _deliverInfo() async {
    snapshot = extractDeviceSnapshot(await getItemInfo(1));
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    List<bool> ethStatusList = [];
    for (String key in (snapshot['ports'] as Map<String, dynamic>).keys) {
      if (key.contains("ethernet")) {
        ethStatusList.add(snapshot['ports'][key]);
      }
    }
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          margin: const EdgeInsets.all(8),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: HardwareStatusCard(
                cpuUsage: snapshot['cpuUsage'] as double,
                ramUsage: snapshot['ramUsage'] as double,
                sfpConnected: snapshot['ports']['optical'],
                ethStatus: ethStatusList,
                usbConnected: snapshot['ports']['USB1'],
              )
          ),
        ),
        InfoCard(
          icon: Icons.info_outline,
          title: I18n.t('local_info'),
          initialFields: [
            FieldItem(
              label: I18n.t('device_model'),
              value: snapshot['deviceModel'],
              icon: Icons.devices_other,
            ),
            FieldItem(
              label: I18n.t('firmware_version'),
              value: snapshot['firmwareVersion'],
              icon: Icons.system_update_alt,
            ),
            FieldItem(
              label: I18n.t('uptime'),
              value: snapshot['uptime'],
              icon: Icons.access_time,
            ),
            FieldItem(
              label: I18n.t('mac_address'),
              value: snapshot['macAddress'],
              icon: Icons.memory,
            ),
            FieldItem(
              label: I18n.t('device_id'),
              value: snapshot['deviceId'],
              icon: Icons.qr_code,
            )
          ],
        ),
      ],
    );
  }
}