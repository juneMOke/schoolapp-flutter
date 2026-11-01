import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_save_cubit.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_bulletin_card.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../bloc/fake_cotes_repository.dart';

const _anglais = CoteCours(
  coursId: 'an',
  branche: 'Anglais',
  maxJournalier: 10,
  maxExamen: 20,
);

/// Deux cours, deux colonnes ouvertes et un examen, pour se déplacer.
const _classe = CoteClasse(
  classroomId: 'c1',
  decoupage: Decoupage.semestre,
  periodes: [
    CotePeriode(
      id: 'S1',
      ordre: 1,
      libelle: 'Semestre 1',
      courant: true,
      locked: false,
      sousPeriodes: [
        CoteSousPeriode(id: 'P1', ordre: 1, locked: false),
        CoteSousPeriode(id: 'P2', ordre: 2, locked: false),
      ],
    ),
  ],
  rubriques: [
    CoteRubrique(id: 'r', cours: [demoFr, _anglais]),
  ],
  eleves: [
    CoteEleve(studentId: 'e1', lastName: 'Ayaka', firstName: 'Ana'),
    CoteEleve(studentId: 'e2', lastName: 'Bola', firstName: 'Ben'),
  ],
);

void main() {
  late FakeCotesRepository repository;
  late CoteSaisieBloc bloc;

  Future<void> pump(
    WidgetTester tester, {
    List<CoteCell> cells = const [],
  }) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repository = FakeCotesRepository(classe: _classe, cells: cells);
    bloc = CoteSaisieBloc(repository);
    final save = CoteSaveCubit(repository);
    bloc.add(const CoteSaisieOpened('c1'));
    await tester.runAsync(
      () => bloc.stream.firstWhere((s) => s is CoteSaisieReady),
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: save),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CoteBulletinCard(classroomName: '7e A'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    addTearDown(() async {
      await tester.runAsync(() async {
        await save.close();
        await bloc.close();
      });
    });
  }

  /// Les champs, ligne par ligne : Français P1, P2, Ex., Anglais P1, P2, Ex.
  Finder field(int index) => find.byType(TextField).at(index);

  bool focused(WidgetTester tester, int index) =>
      tester.widget<TextField>(field(index)).focusNode!.hasFocus;

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  /// La frappe du clavier réel : `tester.enterText` rouvrirait le clavier de
  /// lui-même et masquerait un champ qui n'est plus relié.
  Future<void> typeOnKeyboard(WidgetTester tester, String text) async {
    tester.testTextInput.enterText(text);
    await tester.pump();
    await settle(tester);
  }

  testWidgets('une case vide reçoit le clavier dès le premier tap', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(field(0));
    await tester.pump();
    await typeOnKeyboard(tester, '14');

    expect(tester.widget<TextField>(field(0)).controller!.text, '14');
    final ready = bloc.state as CoteSaisieReady;
    expect(ready.cells.cell('e1', 'fr', 'P1')!.displayedValue, 14);
  });

  testWidgets('Entrée mène à une case vide qui reçoit le clavier', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(field(0));
    await tester.pump();
    await typeOnKeyboard(tester, '14');

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await settle(tester);
    await typeOnKeyboard(tester, '8');

    expect(repository.saved.single.$2, 14);
    expect(tester.widget<TextField>(field(3)).controller!.text, '8');
  });

  testWidgets('une frappe hors barème ne coupe pas le clavier', (tester) async {
    await pump(tester);
    await tester.tap(field(3));
    await tester.pump();

    await typeOnKeyboard(tester, '55');
    await typeOnKeyboard(tester, '5');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await settle(tester);

    expect(repository.invalids, isEmpty);
    expect(repository.saved.single.$2, 5);
  });

  testWidgets('quitter la case écrit, taper non', (tester) async {
    await pump(tester);
    await tester.tap(field(0));
    await tester.pump();

    await typeOnKeyboard(tester, '14');
    expect(repository.saved, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await settle(tester);

    expect(repository.saved.single.$2, 14);
  });

  testWidgets('changer d\'élève sans quitter la case écrit quand même', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(field(0));
    await tester.pump();
    await typeOnKeyboard(tester, '14');

    bloc.add(const CoteStudentSelected('e2'));
    await settle(tester);
    await settle(tester);

    expect(repository.saved.single.$1.studentId, 'e1');
    expect(repository.saved.single.$2, 14);
  });

  testWidgets('Échap sur une cote refusée ne la renvoie pas', (tester) async {
    await pump(
      tester,
      cells: [
        CoteCell(
          key: demoKey('P1'),
          hasDraft: true,
          draftValue: 14,
          syncState: SyncState.syncError,
          rejectionReason: 'OUT_OF_RANGE',
        ),
      ],
    );
    await tester.tap(field(0));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await settle(tester);

    expect(repository.saved, isEmpty);
  });

  testWidgets('Entrée descend au cours suivant', (tester) async {
    await pump(tester);
    await tester.tap(field(0));
    await tester.pump();

    await tester.enterText(field(0), '14');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await settle(tester);

    expect(focused(tester, 3), isTrue);
  });

  testWidgets('les flèches suivent la colonne, et s\'arrêtent au bout', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(field(1));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(focused(tester, 4), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(focused(tester, 4), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(focused(tester, 1), isTrue);
  });

  testWidgets('Échap annule la frappe : retour à la valeur d\'arrivée', (
    tester,
  ) async {
    await pump(tester, cells: [CoteCell(key: demoKey('P1'), serverCote: 14)]);
    await tester.tap(field(0));
    await tester.pump();

    await tester.enterText(field(0), '18');
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);

    final ready = bloc.state as CoteSaisieReady;
    expect(ready.cells.cell('e1', 'fr', 'P1')!.displayedValue, 14);
  });

  testWidgets('Échap sur une valeur calculée ne laisse pas de cote', (
    tester,
  ) async {
    await pump(tester, cells: [CoteCell(key: demoKey('P1'), calculee: 13.25)]);
    await tester.tap(field(0));
    await tester.pump();

    await tester.enterText(field(0), '18');
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);

    final cell = (bloc.state as CoteSaisieReady).cells.cell('e1', 'fr', 'P1')!;
    expect(cell.isCalculated, isTrue);
    expect(cell.displayedValue, 13.25);
    expect(tester.widget<TextField>(field(0)).controller!.text, '13,25');
    expect(repository.saved, isEmpty);
  });

  testWidgets('traverser une valeur calculée n\'écrit rien', (tester) async {
    await pump(tester, cells: [CoteCell(key: demoKey('P1'), calculee: 13.25)]);
    await tester.tap(field(0));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await settle(tester);

    expect(repository.saved, isEmpty);
    expect(repository.invalids, isEmpty);
  });

  testWidgets('une valeur vidée réaffiche la moyenne à la sortie', (
    tester,
  ) async {
    await pump(
      tester,
      cells: [CoteCell(key: demoKey('P1'), serverCote: 15, calculee: 13.25)],
    );
    await tester.tap(field(0));
    await tester.pump();

    await tester.enterText(field(0), '');
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await settle(tester);

    expect(tester.widget<TextField>(field(0)).controller!.text, '13,25');
  });

  testWidgets('la limite de frappe suit le maximum du cours', (tester) async {
    await pump(tester);
    final limiter = tester
        .widget<TextField>(field(0))
        .inputFormatters!
        .whereType<LengthLimitingTextInputFormatter>()
        .single;

    // Français sur 20 : deux chiffres, la virgule, deux décimales.
    expect(limiter.maxLength, 5);
  });

  testWidgets('Alt+→ change d\'élève et place le focus sur une case vide', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(field(0));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await settle(tester);
    await tester.pump();

    expect((bloc.state as CoteSaisieReady).currentId, 'e2');
    expect(focused(tester, 0), isTrue);
  });
}
