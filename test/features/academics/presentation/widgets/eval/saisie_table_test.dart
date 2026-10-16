import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_state.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/saisie_draft_controller.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/saisie_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  const students = [
    NoteEleve(studentId: 's1', firstName: 'Daniel', lastName: 'Kabongo'),
    NoteEleve(studentId: 's2', firstName: 'Grâce', lastName: 'Tshala'),
  ];

  NoteEleveRow row(String id) => NoteEleveRow(
    note: NoteEleve(studentId: id, firstName: 'F$id', lastName: 'L$id'),
  );

  late SaisieDraftController draft;
  setUp(() {
    draft = SaisieDraftController()..initialize([row('s1'), row('s2')], 10);
  });
  tearDown(() => draft.dispose());

  testWidgets('saisie valide → la pastille passe à « Notée »', (tester) async {
    await tester.pumpWidget(
      host(SaisieTable(students: students, draft: draft, inputsEnabled: true)),
    );
    await tester.pumpAndSettle();

    // Deux lignes « En attente » au départ.
    expect(find.text('En attente'), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).first, '7,5');
    await tester.pump();

    expect(find.text('Notée'), findsOneWidget);
    expect(draft.statutFor('s1'), StatutNote.notee);
    expect(draft.pointsFor('s1'), 7.5);
  });

  testWidgets('saisie hors bornes → « max 10 » + non enregistrable', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(SaisieTable(students: students, draft: draft, inputsEnabled: true)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '15');
    await tester.pump();

    expect(find.text('max 10'), findsOneWidget);
    expect(draft.hasErrorFor('s1'), isTrue);
    expect(draft.savableDirtyIds, isEmpty);
  });
  // Le tableau de saisie a son propre repli (ligne empilée sous 560 dp de
  // contenu) : pas d'EteeloMinWidthScroll. On verrouille ici qu'aucune largeur,
  // de part et d'autre de la bascule, ne déborde ni ne crée de défilement.
  for (final width in const [400.0, 600.0, 800.0]) {
    testWidgets(
      'à $width dp : aucun débordement, aucun défilement horizontal',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const longStudents = [
          NoteEleve(
            studentId: 's1',
            firstName: 'Christelle-Bénédicte',
            lastName: 'Mukendi',
            middleName: 'Kalombo',
          ),
        ];
        await tester.pumpWidget(
          host(
            SaisieTable(
              students: longStudents,
              draft: draft,
              inputsEnabled: true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // Le champ texte a son propre Scrollable horizontal : on ne cherche
        // qu'un défilement de mise en page.
        final horizontal = find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal,
        );
        expect(horizontal, findsNothing);
        // Le champ note garde sa largeur, quelle que soit la disposition.
        expect(
          tester.getSize(find.byType(TextField)).width,
          AppDimensions.saisieNoteFieldWidth,
        );
        // Sous la bascule, la ligne empilée rend le nom en entier.
        if (width < 560) {
          final name = tester.renderObject<RenderParagraph>(
            find.byWidgetPredicate(
              (w) => w is RichText && w.text.toPlainText() == 'Mukendi Kalombo',
            ),
          );
          expect(name.didExceedMaxLines, isFalse);
        }
      },
    );
  }
}
