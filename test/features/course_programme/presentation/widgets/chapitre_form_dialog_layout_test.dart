import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_edit.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/form/chapitre_form_dialog.dart';

import '../programme_test_host.dart';

/// La modale d'un chapitre tient partout : téléphone en paysage clavier
/// ouvert (le cas qui fait déborder une modale à saisie), et plein écran
/// sous 600 dp.
void main() {
  Future<void> openAt(
    WidgetTester tester,
    Size size, {
    double keyboard = 0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      programmeHost(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showChapitreFormDialog(
              context,
              cours: kMathsCours,
              chapitre: null,
              sousPeriodes: const [SousPeriodeOption(id: 'sp-1', ordre: 1)],
              newId: () => 'id',
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('paysage, clavier ouvert : rien ne déborde', (tester) async {
    await openAt(tester, const Size(731, 411), keyboard: 200);
    expect(tester.takeException(), isNull);
    expect(find.text('Nouveau chapitre'), findsOneWidget);
  });

  testWidgets('sous 600 dp : la modale occupe l\'écran', (tester) async {
    await openAt(tester, const Size(360, 640));
    expect(tester.takeException(), isNull);
    expect(
      find.byWidgetPredicate(
        (w) => w is Dialog && w.insetPadding == EdgeInsets.zero,
      ),
      findsOneWidget,
    );
  });
}
