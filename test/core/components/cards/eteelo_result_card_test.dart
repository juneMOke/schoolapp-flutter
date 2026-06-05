import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_chip.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_result_card.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';

void main() {
  Widget buildHarness({required Widget child}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 360, child: child)),
      ),
    );
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required VoidCallback onTap,
  }) async {
    await tester.pumpWidget(
      buildHarness(
        child: EteeloResultCard(
          onTap: onTap,
          accentColor: AppColors.bleuArdoise,
          semanticLabel: 'Ouvrir la fiche de Jean Kabila, statut Validé',
          avatar: const CircleAvatar(child: Text('JK')),
          title: const Text('KABILA'),
          subtitle: const Text('Jean'),
          statusPill: const Text('Validé'),
          chips: const [
            EteeloChip(icon: Icons.cake_outlined, label: '15/01/2010'),
          ],
        ),
      ),
    );
  }

  AnimatedContainer animatedContainerOf(WidgetTester tester) {
    return tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byType(EteeloResultCard),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
  }

  BoxDecoration decorationOf(WidgetTester tester) {
    return animatedContainerOf(tester).decoration! as BoxDecoration;
  }

  testWidgets('rend tous les slots attendus', (tester) async {
    await pumpCard(tester, onTap: () {});

    expect(find.text('KABILA'), findsOneWidget);
    expect(find.text('Jean'), findsOneWidget);
    expect(find.text('Validé'), findsOneWidget);
    expect(find.text('15/01/2010'), findsOneWidget);
    expect(find.byType(EteeloChip), findsOneWidget);
  });

  testWidgets('expose une seule action sémantique de type bouton', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await pumpCard(tester, onTap: () {});

    expect(find.byType(InkWell), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
    expect(
      tester.getSemantics(
        find.bySemanticsLabel('Ouvrir la fiche de Jean Kabila, statut Validé'),
      ),
      matchesSemantics(
        label: 'Ouvrir la fiche de Jean Kabila, statut Validé',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('anime hover avec teinte, ombre et translation', (tester) async {
    await pumpCard(tester, onTap: () {});

    final beforeDecoration = decorationOf(tester);
    final beforeTransform = animatedContainerOf(tester).transform;
    expect(beforeDecoration.color, AppColors.surfaceRaised);
    expect(beforeDecoration.boxShadow, AppElevation.shadowKpi);
    expect(beforeTransform?.storage[13] ?? 0, 0);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byType(EteeloResultCard)));
    await tester.pump(AppMotion.fast);

    final afterDecoration = decorationOf(tester);
    final afterTransform = animatedContainerOf(tester).transform;
    expect(
      afterDecoration.color,
      AppColors.bleuArdoise.withValues(alpha: 0.06),
    );
    expect(afterDecoration.boxShadow!.first, AppElevation.shadowRaised.first);
    expect(
      afterTransform?.storage[13],
      AppDimensions.resultCardHoverTranslateY,
    );
  });

  testWidgets('affiche un anneau de focus visible', (tester) async {
    await pumpCard(tester, onTap: () {});

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    inkWell.focusNode?.requestFocus();
    await tester.pumpAndSettle();

    final decoration = decorationOf(tester);
    expect(
      decoration.boxShadow!.any(
        (shadow) =>
            shadow.color == AppColors.stateFocus && shadow.spreadRadius == 2,
      ),
      isTrue,
    );
  });

  testWidgets('déclenche onTap', (tester) async {
    var tapCount = 0;
    await pumpCard(tester, onTap: () => tapCount++);

    await tester.tap(find.byType(EteeloResultCard));
    await tester.pump();

    expect(tapCount, 1);
  });
}
