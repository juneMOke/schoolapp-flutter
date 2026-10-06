import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_bloc.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/contenu/chapitre_contenu_section.dart';

import '../programme_test_host.dart';

void main() {
  late List<(List<ChapitreBloc>, bool)> saves;

  Future<bool> onSave(List<ChapitreBloc> blocs, {bool announce = true}) async {
    saves.add((blocs, announce));
    return true;
  }

  Widget section({
    List<ChapitreBloc> blocs = const [],
    bool canWrite = true,
    List<String> permissions = kProgrammeTeacher,
  }) {
    var n = 0;
    return programmeHost(
      SingleChildScrollView(
        child: ChapitreContenuSection(
          blocs: blocs,
          canWrite: canWrite,
          newId: () => 'b-${n++}',
          onSave: onSave,
        ),
      ),
      permissions: permissions,
    );
  }

  setUp(() => saves = []);

  testWidgets('la lecture rend les blocs ; la direction ne rédige pas', (
    tester,
  ) async {
    await tester.pumpWidget(
      section(
        canWrite: false,
        permissions: kProgrammeReader,
        blocs: const [
          ChapitreBloc(
            id: 't',
            type: ChapitreBlocType.titre,
            texte: 'Notions clés',
          ),
          ChapitreBloc(
            id: 'e',
            type: ChapitreBlocType.encadre,
            texte: 'Justifier.',
          ),
        ],
      ),
    );
    expect(find.text('Notions clés'), findsOneWidget);
    expect(find.text('À RETENIR'), findsOneWidget);
    expect(find.text('Rédiger'), findsNothing);
  });

  testWidgets('rédiger un contenu vide, puis Terminer l\'enregistre', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(section());

    await tester.tap(find.text('Rédiger le contenu'));
    await tester.pumpAndSettle();
    expect(find.text('Titre de section'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Introduction');
    await tester.tap(find.text('Terminer'));
    await tester.pumpAndSettle();

    final (blocs, announce) = saves.last;
    expect(announce, isTrue);
    expect(blocs.single.texte, 'Introduction');
    expect(
      find.text('Introduction'),
      findsNothing,
      reason: 'la section relit ses blocs depuis le chapitre',
    );
  });

  testWidgets('deux secondes sans frappe : le brouillon part en silence', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      section(
        blocs: const [
          ChapitreBloc(
            id: 'p',
            type: ChapitreBlocType.paragraphe,
            texte: 'Avant',
          ),
        ],
      ),
    );
    await tester.tap(find.text('Rédiger'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Après');
    await tester.pump(const Duration(seconds: 1));
    expect(saves, isEmpty);
    await tester.pump(const Duration(seconds: 2));

    expect(saves.single.$2, isFalse);
    expect(saves.single.$1.single.texte, 'Après');
  });
}
