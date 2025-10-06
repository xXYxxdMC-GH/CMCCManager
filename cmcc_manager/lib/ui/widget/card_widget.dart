import 'package:flutter/material.dart';

import '../../global.dart';
import '../../main.dart';
import '../../utils/network_utils.dart';
import '../../utils/string_html_util.dart';
import 'info_widget.dart';
import 'item_widget.dart';
import 'other_widget.dart';

class InfoCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool singleLinePerField;
  final List<FieldItem> initialFields;
  final String subTitle;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    this.subTitle = "",
    required this.initialFields,
    this.singleLinePerField = false,
  });

  @override
  State<InfoCard> createState() => InfoCardState();
}

class InfoCardState extends State<InfoCard> {
  late List<FieldItem> fields;

  @override
  void initState() {
    super.initState();
    fields = widget.initialFields;
  }

  void updateFields(List<FieldItem> newFields) {
    setState(() => fields = newFields);
  }

  @override
  void didUpdateWidget(covariant InfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFields != oldWidget.initialFields) {
      setState(() {
        fields = widget.initialFields;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double fieldWidth = (MediaQuery.of(context).size.width - 100) / 2;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, size: 40, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.subTitle != "") Text(
                        widget.subTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: fields.map((field) {
                return SizedBox(
                  width: fieldWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (field.icon != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(field.icon, size: 22, color: Colors.grey[700]),
                        ),
                      if (field.icon != null) const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(field.label,
                                style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) => FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                              child: Text(
                                field.value,
                                key: ValueKey(field.value),
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )

          ],
        ),
      ),
    );
  }
}

class DeviceInfoCard extends StatefulWidget {
  final IconData icon;
  final DeviceInfo info;
  final String name;

  const DeviceInfoCard({
    super.key,
    required this.name,
    required this.icon,
    required this.info,
  });

  @override
  State<DeviceInfoCard> createState() => _DeviceInfoCardState();
}

class _DeviceInfoCardState extends State<DeviceInfoCard> with TickerProviderStateMixin {
  late AnimationController cooldownController;
  @override
  void initState() {
    super.initState();
    cooldownController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000),
    )..addListener(() {
      setState(() {
        cooldownProgress = 1.0 - cooldownController.value;
      });
    })..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => isCoolingDown = false);
      }
    });
  }

  @override
  void dispose() {
    cooldownController.dispose();
    super.dispose();
  }

  bool isCoolingDown = false;
  double cooldownProgress = 1.0;

  void triggerCooldown() {
    if (isCoolingDown) return;
    setState(() => isCoolingDown = true);
    cooldownController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double fieldWidth = (MediaQuery.of(context).size.width - 24) / 2;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                  child: Icon(widget.icon, size: 36, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name == "" ? widget.info.name : widget.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20
                          )
                      ),
                      Text(widget.info.ip,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          )
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("↑${formatBandwidth(widget.info.upstream.toString())}bp/s",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          )),
                      Text("↓${formatBandwidth(widget.info.downstream.toString())}bp/s",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: fieldWidth,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.memory,
                        size: 20,
                        color: theme.iconTheme.color?.withAlpha((0.6 * 255).toInt())),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("MAC 物理地址",
                            style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
                        const SizedBox(height: 4),
                        Text(widget.info.mac,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSwitchRow(context, '外网访问', widget.info.mac, 0, widget.info.internetAccess, widget.info.storageAccess),
                _buildSwitchRow(context, '存储访问', widget.info.mac, 1, widget.info.internetAccess, widget.info.storageAccess),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow(BuildContext context, String label, String mac, int option, bool internetAccess, bool storageAccess) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(width: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            Switch(
              value: option == 0 ? internetAccess : storageAccess,
              onChanged: isCoolingDown ? null : (value) {
                switchPermission(mac, !value, option, internetAccess, storageAccess);
                devicePageKey.currentState?.deliverInfo();
                setState(() {});
                triggerCooldown();
              },
            ),
            if (isCoolingDown) AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: isCoolingDown ? 4 * cooldownProgress : 0,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),

          ],
        )
      ],
    );
  }
}

class HardwareStatusCard extends StatefulWidget {
  final double cpuUsage;
  final double ramUsage;
  final bool sfpConnected;
  final List<bool> ethStatus;
  final bool usbConnected;


  const HardwareStatusCard({
    super.key,
    required this.cpuUsage,
    required this.ramUsage,
    required this.sfpConnected,
    required this.ethStatus,
    required this.usbConnected,
  });

  @override
  State<StatefulWidget> createState() => _HardwareStatusCardState();
}

class _HardwareStatusCardState extends State<HardwareStatusCard> {
  @override
  void initState() {
    super.initState();
  }

  Color _getUsageColor(double value) {
    if (value < 50) return Colors.green;
    if (value < 80) return Colors.orange;
    return Colors.red;
  }

  Widget _buildCircularIndicator({
    required String label,
    required double value,
    required double size,
    required double strokeWidth,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value / 100),
      curve: Curves.easeOutBack,
      duration: const Duration(milliseconds: 600),
      builder: (context, animatedValue, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size + 20,
              height: size - 10,
              child: RoundedCircularIndicator(
                value: animatedValue,
                size: size,
                strokeWidth: strokeWidth,
                backgroundColor: isDarkMode ? Colors.black38 : Colors.grey[300]!,
                foregroundColor: AlwaysStoppedAnimation<Color>(_getUsageColor(value)).value,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 15)),
                Text("${value.toInt()}%", style: const TextStyle(fontSize: 15)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPortStatus({
    required IconData icon,
    required String label,
    required bool isConnected,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isConnected ? Colors.green : Colors.grey),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
              fontSize: 14,
              color: isConnected ? Colors.green : Colors.grey,
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.memory, color: Colors.blueAccent, size: 45),
              SizedBox(width: 8),
              Text("性能概览",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCircularIndicator(
                label: "CPU",
                value: widget.cpuUsage,
                size: 80,
                strokeWidth: 16,
              ),
              _buildCircularIndicator(
                label: "Memory",
                value: widget.ramUsage,
                size: 100,
                strokeWidth: 26,
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text("接口状态",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPortStatus(
                icon: Icons.wifi_tethering,
                label: "光口",
                isConnected: widget.sfpConnected,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  for (int i = 0; i < widget.ethStatus.length; i++)
                    _buildPortStatus(
                      icon: Icons.settings_ethernet,
                      label: "网口 ${i + 1}",
                      isConnected: widget.ethStatus[i],
                    ),
                ],
              ),
              const SizedBox(height: 6),
              _buildPortStatus(
                icon: Icons.usb,
                label: "USB",
                isConnected: widget.usbConnected,
              ),
            ],
          ),
        ],
      ),
    );
  }
}