import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_edit.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/form/chapitre_form_dialog.dart';

import '../programme_test_host.dart';

void main() {
  ChapitreEdit? result;

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      programmeHost(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              var n = 0;
              result = await showChapitreFormDialog(
                context,
                cours: kMathsCours,
                chapitre: null,
                sousPeriodes: const [SousPeriodeOption(id: 'sp-1', ordre: 1)],
                newId: () => 'id-${n++}',
              );
            },
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  setUp(() => result = null);

  testWidgets('le titre se juge à la soumission, puis l\'édition revient', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Nouveau chapitre'), findsOneWidget);
    expect(find.text('MATHÉMATIQUES — 7E A'), findsOneWidget);
    expect(find.text('Le titre du chapitre est obligatoire.'), findsNothing);

    await tester.tap(find.text('Créer le chapitre'));
    await tester.pumpAndSettle();
    expect(find.text('Le titre du chapitre est obligatoire.'), findsOneWidget);
    expect(result, isNull);

    await tester.enterText(find.byType(TextField).first, 'Fractions');
    await tester.tap(find.text('En cours'));
    await tester.tap(find.text('Créer le chapitre'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.isNew, isTrue);
    expect(result!.chapitre.titre, 'Fractions');
    expect(result!.chapitre.sousPeriodeId, 'sp-1');
  });
}
