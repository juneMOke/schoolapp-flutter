import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_grid_hint_band.dart';

import '../bloc/fake_cotes_repository.dart';
import 'cote_grid_hint_band_harness.dart';

/// Français P1 : une cote qui remplace la moyenne des évaluations.
final _replaces = CoteCell(key: demoKey('P1'), serverCote: 15, calculee: 13.25);

/// Anglais P1 : une cote refusée, colonne clôturée entre-temps.
final _rejected = CoteCell(
  key: demoKey('P1', cours: 'an'),
  hasDraft: true,
  draftValue: 8,
  syncState: SyncState.syncError,
  rejectionReason: 'PERIODE_CLOSE',
);

void main() {
  setUp(() {
    // Le clavier matériel : le parcours au Tab et aux flèches.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });

  testWidgets('la bande montre l\'aide de la case au focus, et rien sinon', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpHintBulletin(tester, cells: [_replaces]);
    expect(find.byType(CoteGridHintBand), findsOneWidget);
    expect(bandText(tester), isEmpty);

    await tester.tap(gridField(0));
    await tester.pump();
    expect(
      bandText(tester),
      'Français · 1re période : Moyenne des évaluations : 13,25',
    );

    // Français P2 : vide, pas d'aide.
    await tester.tap(gridField(1));
    await tester.pump();
    expect(bandText(tester), isEmpty);

    // Hors de la grille : vide.
    await tester.tap(gridField(0));
    await tester.pump();
    expect(bandText(tester), isNotEmpty);
    await tester.tap(find.byKey(outsideFieldKey));
    await tester.pump();
    expect(bandText(tester), isEmpty);
  });

  testWidgets('les flèches et Tab font suivre la bande', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpHintBulletin(tester, cells: [_replaces, _rejected]);

    await tester.tap(gridField(0));
    await tester.pump();
    expect(bandText(tester), contains('13,25'));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(
      bandText(tester),
      'Anglais · 1re période : Refusée : colonne clôturée entre-temps. '
      'Le serveur ne l\'a pas gardée.',
    );

    // Anglais P2, vide.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(bandText(tester), isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(bandText(tester), contains('13,25'));
  });

  testWidgets('la bande suit la frappe sans rien écrire avant la sortie', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = await pumpHintBulletin(
      tester,
      cells: [_replaces, _rejected],
    );

    // Parcourir les cases à aide n'écrit rien.
    await tester.tap(gridField(0));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await settleHint(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await settleHint(tester);
    expect(bandText(tester), contains('13,25'));

    // Hors barème : l'aide le dit tout de suite, rien ne part.
    tester.testTextInput.enterText('55');
    await settleHint(tester);
    expect(bandText(tester), contains('Note invalide : de 0 à 20'));

    // Corrigée : l'aide revient à la moyenne, toujours rien d'écrit.
    tester.testTextInput.enterText('14');
    await settleHint(tester);
    expect(bandText(tester), contains('13,25'));
    expect(repository.saved, isEmpty);
    expect(repository.invalids, isEmpty);
    expect(repository.clearedInvalid, isEmpty);
    expect(repository.discarded, isEmpty);

    // Quitter la case l'écrit, une fois.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await settleHint(tester);
    expect(repository.saved.single, (demoKey('P1'), 14.0));
    expect(repository.invalids, isEmpty);
  });

  testWidgets('la bande reste hors du lecteur d\'écran : la case parle', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    await pumpHintBulletin(tester, cells: [_replaces]);
    // Les lignes entrent en fondu : invisibles au lecteur tant qu'il dure.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(gridField(0));
    await tester.pump();
    expect(bandText(tester), contains('13,25'));

    // L'aide n'est dite qu'une fois : par la case, en indication.
    final cells = find.bySemanticsLabel(RegExp('Français · 1re période'));
    expect(cells, findsOneWidget);
    final cell = tester.getSemantics(cells);
    expect(cell.hint, 'Moyenne des évaluations : 13,25');
    expect(cell.tooltip, isNot(contains('13,25')));
    expect(find.bySemanticsLabel(RegExp('13,25')), findsNothing);
    semantics.dispose();
  });
}
