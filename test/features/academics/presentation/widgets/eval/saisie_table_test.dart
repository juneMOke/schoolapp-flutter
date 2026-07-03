import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
