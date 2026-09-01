import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/motion/eteelo_entrance.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  List<double> opacities(WidgetTester tester) => tester
      .widgetList<Opacity>(
        find.descendant(
          of: find.byType(EteeloEntrance),
          matching: find.byType(Opacity),
        ),
      )
      .map((o) => o.opacity)
      .toList();

  testWidgets('les blocs se posent en cascade, du haut vers le bas', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            EteeloEntrance(index: 0, child: Text('premier')),
            EteeloEntrance(index: 3, child: Text('dernier')),
          ],
        ),
      ),
    );

    // Le minuteur du rang 0 part a la premiere avance du temps ; celui du
    // rang 3 attend 180 ms.
    await tester.pump(AppMotion.stagger);
    await tester.pump(AppMotion.stagger);

    final posing = opacities(tester);
    expect(posing.first, greaterThan(0));
    expect(posing.last, 0);

    await tester.pumpAndSettle();

    expect(opacities(tester), everyElement(1.0));
  });

  testWidgets('le rang est republie au contenu qui s anime lui-meme', (
    tester,
  ) async {
    late int inCascade;
    late int alone;

    await tester.pumpWidget(
      host(
        Column(
          children: [
            EteeloEntrance(
              index: 2,
              child: Builder(
                builder: (context) {
                  inCascade = EntranceRank.of(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
            Builder(
              builder: (context) {
                alone = EntranceRank.of(context);
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );

    expect(inCascade, 2);
    // Hors cascade, rien a attendre.
    expect(alone, 0);
  });
}
