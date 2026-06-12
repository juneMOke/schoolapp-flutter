import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';

void main() {
  // Anatomie d'une ligne : avatar + 2 lignes d'identite + 2 pilules = 5 blocs.
  const blocksPerRow = 5;

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('rend le nombre de lignes demande et porte le libelle a11y', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const EteeloListSkeleton(rowCount: 3, semanticsLabel: 'Chargement')),
    );
    // Pas de pumpAndSettle : le pouls boucle indefiniment.
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byType(EteeloSkeletonBox), findsNWidgets(3 * blocksPerRow));
    expect(tester.getSemantics(find.bySemanticsLabel('Chargement')), isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('respecte reduced-motion (rend statiquement sans animation)', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: EteeloListSkeleton(rowCount: 2),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byType(EteeloSkeletonBox), findsNWidgets(2 * blocksPerRow));
    expect(tester.takeException(), isNull);
  });

  testWidgets('peut masquer l avatar et ajuster le nombre de pilules', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const EteeloListSkeleton(rowCount: 1, showAvatar: false, pillCount: 1),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));

    // Sans avatar (0) + 2 lignes identite + 1 pilule = 3 blocs.
    expect(find.byType(EteeloSkeletonBox), findsNWidgets(3));
  });
}
