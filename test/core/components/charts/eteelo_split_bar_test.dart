import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_split_bar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';

/// Monte la barre dans une largeur connue, pour que les proportions se mesurent.
Future<void> _pump(
  WidgetTester tester,
  List<EteeloSplitBarSegment> segments, {
  bool reduceMotion = true,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: EteeloSplitBar(
                  segments: segments,
                  semanticsLabel: '182 filles, 181 garçons',
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _girls = EteeloSplitBarSegment(
  label: 'Filles',
  valueLabel: '182 · 50 %',
  value: 182,
  color: AppColors.enrollmentStatsFemale,
);

const _boys = EteeloSplitBarSegment(
  label: 'Garçons',
  valueLabel: '181 · 50 %',
  value: 181,
  color: AppColors.enrollmentStatsMale,
);

void main() {
  testWidgets('la légende écrit chaque libellé ET sa valeur', (tester) async {
    await _pump(tester, const [_girls, _boys]);

    // Aucune information n'est portée par la seule couleur : le libellé et la
    // valeur sont écrits pour chaque segment.
    expect(find.text('Filles'), findsOneWidget);
    expect(find.text('182 · 50 %'), findsOneWidget);
    expect(find.text('Garçons'), findsOneWidget);
    expect(find.text('181 · 50 %'), findsOneWidget);
  });

  testWidgets('la barre porte une phrase a11y qui contient les valeurs', (
    tester,
  ) async {
    await _pump(tester, const [_girls, _boys]);

    expect(find.bySemanticsLabel('182 filles, 181 garçons'), findsOneWidget);
  });

  testWidgets('les largeurs suivent la part de chaque segment', (tester) async {
    // 3 contre 1 : le premier segment doit occuper trois fois le second.
    await _pump(tester, const [
      EteeloSplitBarSegment(
        label: 'A',
        valueLabel: '300',
        value: 300,
        color: Color(0xFF111111),
      ),
      EteeloSplitBarSegment(
        label: 'B',
        valueLabel: '100',
        value: 100,
        color: Color(0xFF222222),
      ),
    ]);

    final boxes = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .where(
          (box) =>
              box.color == const Color(0xFF111111) ||
              box.color == const Color(0xFF222222),
        )
        .toList();
    expect(boxes, hasLength(2));

    final a = tester.getSize(
      find
          .ancestor(
            of: find.byWidget(boxes[0]),
            matching: find.byType(Expanded),
          )
          .first,
    );
    final b = tester.getSize(
      find
          .ancestor(
            of: find.byWidget(boxes[1]),
            matching: find.byType(Expanded),
          )
          .first,
    );
    expect(a.width / b.width, closeTo(3.0, 0.05));
  });

  testWidgets('un total nul rend la piste et des zéros, pas un trou', (
    tester,
  ) async {
    // Le cas d'une école le jour de l'ouverture : c'est un état, pas une
    // absence de rendu.
    await _pump(tester, const [
      EteeloSplitBarSegment(
        label: 'Filles',
        valueLabel: '0 · 0 %',
        value: 0,
        color: AppColors.enrollmentStatsFemale,
      ),
      EteeloSplitBarSegment(
        label: 'Garçons',
        valueLabel: '0 · 0 %',
        value: 0,
        color: AppColors.enrollmentStatsMale,
      ),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('Filles'), findsOneWidget);
    expect(find.text('0 · 0 %'), findsNWidgets(2));
    // La piste occupe toute la largeur offerte.
    expect(
      tester.getSize(find.byType(ClipRRect).first).width,
      closeTo(400, 0.5),
    );
  });

  testWidgets('sans reduced-motion la barre s\'anime puis se stabilise', (
    tester,
  ) async {
    await _pump(tester, const [_girls, _boys], reduceMotion: false);
    expect(tester.takeException(), isNull);
    expect(find.text('Filles'), findsOneWidget);
  });
}
