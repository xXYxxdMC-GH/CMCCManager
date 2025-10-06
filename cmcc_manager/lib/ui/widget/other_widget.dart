import 'package:flutter/material.dart';

import 'item_widget.dart';

class RoundedCircularIndicator extends StatelessWidget {
  final double value; // 0.0 ~ 1.0
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final Color foregroundColor;

  const RoundedCircularIndicator({
    super.key,
    required this.value,
    required this.size,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RoundedCircularPainter(
          value: value,
          strokeWidth: strokeWidth,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        ),
      ),
    );
  }
}

class _RoundedCircularPainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final Color backgroundColor;
  final Color foregroundColor;

  _RoundedCircularPainter({
    required this.value,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final foregroundPaint = Paint()
      ..color = foregroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final pi = 3.1415926;

    final sweepAngle = 2 * pi * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<SettingsItem> children;

  const SettingsSection({
    required this.icon,
    required this.title,
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: theme.iconTheme.color),
                const SizedBox(width: 12),
                Text(title, style: TextStyle(fontSize: 18, color: theme.textTheme.bodyMedium?.color)),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}