import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/balance_chart_painters.dart';

Widget _ring({required bool reduced}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduced),
  child: const Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(
      width: 300,
      height: 200,
      child: TreasuryPulsingRing(
        x: 3,
        y: 50,
        count: 5,
        maxY: 100,
        left: 74,
        bottom: 30,
      ),
    ),
  ),
);

void main() {
  testWidgets('le dernier point pulse', (tester) async {
    await tester.pumpWidget(_ring(reduced: false));
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('animations réduites : l anneau reste fixe', (tester) async {
    await tester.pumpWidget(_ring(reduced: true));
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
