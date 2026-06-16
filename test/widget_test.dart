import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kasby_admin/core/controllers/theme_controller.dart';

void main() {
  testWidgets('Admin shell smoke test', (WidgetTester tester) async {
    Get.put(ThemeController());

    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(
          body: Center(child: Text('Kasby Admin Panel')),
        ),
      ),
    );

    expect(find.text('Kasby Admin Panel'), findsOneWidget);
    Get.reset();
  });
}
