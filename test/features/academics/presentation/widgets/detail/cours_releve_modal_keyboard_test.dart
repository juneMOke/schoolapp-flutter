import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/moyenne_eleve.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_releve_modal.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// B-9 — le relevé par élève n'a aucun champ, donc le clavier ne monte jamais
/// devant lui. Il s'ouvre en revanche depuis le détail d'un cours, où un
/// clavier peut être levé : `Dialog` ajoute alors les `viewInsets` à son
/// `insetPadding`, et il ne reste qu'une poignée de dp pour un en-tête qui en
/// réclame près de cent.
///
/// La seule des sept modales du lot qui n'avait aucun test : elle en reçoit un
/// au moment où on la touche.
BucketVm _bucket() => const BucketVm(
  key: 'sp:1',
  kind: BucketKind.sousPeriode,
  ordre: 1,
  statut: BucketStatut.current,
  evaluations: [],
  moyenneClasse: 62.5,
  nombreElevesNotes: 3,
  nombreEleves50: 2,
  moyennesEleves: [
    MoyenneEleve(
      studentId: 's1',
      firstName: 'Awa',
      lastName: 'Mbala',
      moyenne: 78,
    ),
    MoyenneEleve(
      studentId: 's2',
      firstName: 'Junior',
      lastName: 'Kabeya',
      moyenne: 47,
    ),
    MoyenneEleve(studentId: 's3', firstName: 'Sarah', lastName: 'Ilunga'),
  ],
  supportsReleve: true,
  saisiesNotes: 6,
  totalNotes: 9,
);

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showCoursReleveModal(
              context,
              brancheNom: 'Mathématiques',
              classroomName: '6e A',
              label: 'Trimestre 1',
              bucket: _bucket(),
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rendu nominal : en-tête, tri et liste', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _open(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(EteeloDialogBody), findsOneWidget);
    expect(find.textContaining('Mbala'), findsOneWidget);
  });

  testWidgets('téléphone en PAYSAGE, clavier déjà levé : rien ne déborde', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(731, 411);
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);

    await _open(tester);

    expect(tester.takeException(), isNull);
    // Le contenu reste ATTEIGNABLE : la coquille rend l'ensemble défilable au
    // lieu de rogner l'en-tête.
    expect(find.byType(EteeloDialogBody), findsOneWidget);
  });
}
