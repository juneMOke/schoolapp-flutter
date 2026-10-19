import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_state.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/saisie_draft_controller.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/saisie_focus.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/saisie_numpad.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// En paysage, le pavé passe à côté de la note : sur une tablette de 600 dp
/// de haut, la carte empilée défilait à chaque élève.
void main() {
  const students = [
    NoteEleve(studentId: 's1', firstName: 'Ada', lastName: 'Kabeya'),
    NoteEleve(studentId: 's2', firstName: 'Ben', lastName: 'Mutombo'),
  ];

  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final draft = SaisieDraftController()
      ..initialize([for (final s in students) NoteEleveRow(note: s)], 20);
    addTearDown(draft.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SaisieFocus(
              students: students,
              draft: draft,
              inputsEnabled: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('paysage : pavé à droite de la note, sans défiler', (
    tester,
  ) async {
    await pump(tester, const Size(960, 600));

    final pad = tester.getRect(find.byType(SaisieNumpad));
    final name = tester.getRect(find.textContaining('Kabeya').first);
    expect(pad.left, greaterThan(name.right));
    expect(pad.bottom, lessThanOrEqualTo(600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait : pavé sous la note', (tester) async {
    await pump(tester, const Size(600, 960));

    final pad = tester.getRect(find.byType(SaisieNumpad));
    final name = tester.getRect(find.textContaining('Kabeya').first);
    expect(pad.top, greaterThan(name.bottom));
  });
}
