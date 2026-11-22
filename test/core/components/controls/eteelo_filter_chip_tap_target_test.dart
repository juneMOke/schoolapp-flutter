import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

Widget _chip({required bool padded, required VoidCallback onTap}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Wrap(
            children: [
              EteeloFilterChip(
                label: 'Langues',
                selected: false,
                color: Colors.blue,
                soft: Colors.white,
                ink: Colors.black,
                padTapTarget: padded,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );

void main() {
  testWidgets('zone de toucher portée à 48 dp, la puce garde sa hauteur', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(_chip(padded: true, onTap: () => taps++));
    final area = tester.getRect(find.byType(EteeloFilterChip));
    final chip = tester.getRect(find.byType(Material).last);
    expect(area.height, AppDimensions.minTouchTarget);
    expect(chip.height, AppDimensions.filterChipHeight);
    // Un toucher dans la marge, au-dessus de la puce, compte.
    await tester.tapAt(Offset(area.center.dx, area.top + 1));
    expect(taps, 1);
    await tester.tap(find.text('Langues'));
    expect(taps, 2);
  });

  testWidgets('sans l’option, rien ne change', (tester) async {
    await tester.pumpWidget(_chip(padded: false, onTap: () {}));
    expect(
      tester.getSize(find.byType(EteeloFilterChip)).height,
      AppDimensions.filterChipHeight,
    );
  });
}
