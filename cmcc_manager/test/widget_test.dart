// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:cmcc_manager/core/translate.dart';
import 'package:cmcc_manager/main.dart';
import 'package:cmcc_manager/ui/page/pattern_lock_set_page.dart';
import 'package:cmcc_manager/ui/widget/card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pattern_lock/pattern_lock.dart';

void main() {
  testWidgets('PatternLockSetupPage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: HardwareStatusCard(cpuUsage: 10, ramUsage: 10, sfpConnected: true, ethStatus: [], usbConnected: true,)));
  });

}
