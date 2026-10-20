import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/buttons/primary_action_placement.dart';

void main() {
  Future<bool> inPageAt(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late bool inPage;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            inPage = primaryActionInPage(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return inPage;
  }

  testWidgets(
    'au doigt : flottant sous 1 024, dans la page au-delà',
    (tester) async {
      expect(await inPageAt(tester, 900), isFalse);
      expect(await inPageAt(tester, 1024), isTrue);
    },
    variant: TargetPlatformVariant.mobile(),
  );

  testWidgets(
    'à la souris : dans la page dès qu\'on quitte le téléphone',
    (tester) async {
      expect(await inPageAt(tester, 700), isFalse);
      expect(await inPageAt(tester, 900), isTrue);
    },
    variant: TargetPlatformVariant.desktop(),
  );
}
