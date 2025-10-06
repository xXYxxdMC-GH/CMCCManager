
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../utils/network_utils.dart';
import '../widget/card_widget.dart';
import '../widget/info_widget.dart';

class DeviceOperatePage extends StatefulWidget {
  const DeviceOperatePage({super.key});

  @override
  State<StatefulWidget> createState() => DeviceOperatePageState();
}

class DeviceOperatePageState extends State<DeviceOperatePage> with AutomaticKeepAliveClientMixin {
  late final Timer timer;
  List<DeviceInfo> infos = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    deliverInfo();
    timer = Timer.periodic((Duration(seconds: 3)), (_) {
      setState(() {
        deliverInfo();
      });
    });
    super.initState();
  }

  void deliverInfo() async {
    final result = await extractDevices();
    if (!mounted) return;

    if (!listEquals(result, infos)) {
      setState(() {
        infos = result;
      });
    }
  }


  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  IconData getIcon(String name, String ip) {
    if (name.contains("HUAWEI_MatePad")) {
      return Icons.tablet_mac;
    } else if (name.contains("vivo-X50") || name.contains("magic") || name.contains("ALN")) {
      return Icons.phone_android;
    } else if (name == "anonymous" && ip == "192.168.1.9"){
      return Icons.tv_sharp;
    } else if (name.contains("YR1901G")) {
      return Icons.wifi;
    } else {
      return Icons.device_unknown;
    }
  }

  String getName(String name, String ip) {
    if (name.contains("HUAWEI_MatePad")) {
      return "华为MatePad";
    } else if (name.contains("vivo-X50")) {
      return "VIVO X50";
    } else if (name.contains("magic")) {
      return "荣耀Magic6";
    } else if (name.contains("ALN")) {
      return "华为Mate60";
    } else if (name == "anonymous" && ip == "192.168.1.9") {
      return "电视";
    } else if (name.contains("YR1901G")) {
      return "路由器";
    } else {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      children: infos.map((info) {
        final key = ValueKey(info.mac);
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: DeviceInfoCard(
            key: key,
            icon: getIcon(info.name, info.ip),
            name: getName(info.name, info.ip),
            info: info,
          ),
        );
      }).toList(),
    );
  }
}