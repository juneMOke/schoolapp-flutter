import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/layout/tap_target_height.dart';

void main() {
  Future<double> heightOn(WidgetTester tester) async {
    late double height;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            height = TapTargetHeight.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return height;
  }

  testWidgets('au doigt : 48 dp', (tester) async {
    expect(await heightOn(tester), AppDimensions.minTouchTarget);
  }, variant: TargetPlatformVariant.mobile());

  testWidgets(
    'à la souris (bureau, navigateur de bureau) : 40 dp',
    (tester) async {
      expect(await heightOn(tester), AppDimensions.pointerControlHeight);
    },
    variant: TargetPlatformVariant.desktop(),
  );
}
