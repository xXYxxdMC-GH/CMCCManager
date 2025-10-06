import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/translate.dart';
import '../../global.dart';
import '../../main.dart';
import '../../utils/network_utils.dart';
import '../../utils/string_html_util.dart';
import '../../utils/widget_utils.dart';
import '../widget/card_widget.dart';
import '../widget/info_widget.dart';
import '../widget/item_widget.dart';

class FiberPage extends StatefulWidget {
  final Key cardKey;
  final Key cardKey1;

  const FiberPage({
    required this.cardKey,
    required this.cardKey1,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _FiberPageState();
}

class _FiberPageState extends State<FiberPage> with AutomaticKeepAliveClientMixin {
  late final Timer timer;
  late final Timer timer2;
  TempleUserInfo info = TempleUserInfo();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    _deliverInfo();
    timer = Timer.periodic(Duration(seconds: 2), (_) {
      setState(() {});
    });
    timer2 = Timer.periodic(Duration(seconds: 10), (_) {
      setState(() {
        _deliverInfo();
      });
    });
    super.initState();
  }

  void _deliverInfo() async {
    final result = await getTempleUserInfo();
    if (!mounted) return;
    setState(() {
      info = result;
    });
  }


  @override
  void dispose() {
    timer.cancel();
    timer2.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        InfoCard(
          key: cardKey,
          icon: Icons.network_check,
          title: I18n.t('optical_network_status'),
          subTitle: "↑${formatBandwidth(gi1)}bp/s ↓${formatBandwidth(gi2)}bp/s",
          initialFields: [
            FieldItem(label: I18n.t('tx_power'), value: info.sendLightPower, icon: Icons.light_mode),
            FieldItem(label: I18n.t('rx_power'), value: info.receiveLightPower, icon: Icons.light_mode_outlined),
            FieldItem(label: I18n.t('working_voltage'), value: info.workVoltage, icon: Icons.bolt),
            FieldItem(label: I18n.t('working_current'), value: info.workCorrect, icon: Icons.change_history),
            FieldItem(label: I18n.t('working_temperature'), value: info.temperature, icon: Icons.device_thermostat),
            FieldItem(label: I18n.t('authentication_status'), value: info.verificationStatus, icon: Icons.fingerprint),
          ],
        ),
        InfoCard(
          key: cardKey1,
          icon: Icons.public,
          title: I18n.t('network_service_status'),
          singleLinePerField: false,
          initialFields: buildFieldItems(),
        ),
      ],
    );
  }
}