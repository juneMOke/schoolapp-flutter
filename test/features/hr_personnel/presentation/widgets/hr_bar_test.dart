import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_bar.dart';

void main() {
  const red = Color(0xFFAA0000);
  const blue = Color(0xFF0000AA);

  Future<void> pumpBar(WidgetTester tester) => tester.pumpWidget(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 200,
          child: HrBar(
            segments: [
              HrBarSegment(count: 1, color: red),
              HrBarSegment(count: 1, color: blue),
            ],
            scale: 4,
            height: 10,
          ),
        ),
      ),
    ),
  );

  Size segment(WidgetTester tester, Color color) => tester.getSize(
    find.byWidgetPredicate((w) => w is ColoredBox && w.color == color),
  );

  testWidgets('chaque segment se peint sur toute la hauteur de la barre', (
    tester,
  ) async {
    await pumpBar(tester);

    // Sans hauteur imposée, un `ColoredBox` sans enfant se réduit à 0 dp :
    // la barre ne montrait que sa piste grise.
    expect(segment(tester, red), const Size(50, 10));
    expect(segment(tester, blue), const Size(50, 10));
  });
}
