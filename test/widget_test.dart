import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zrok_mobile/src/app/di/app_scope.dart';
import 'package:zrok_mobile/src/app/view/zrok_app.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const AppScope(child: ZrokApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
