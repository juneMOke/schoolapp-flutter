import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/moyenne_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_bucket_panel.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_releve_modal.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  // Animations désactivées : le point pulsé « en cours » boucle indéfiniment et
  // ferait expirer pumpAndSettle (exerce aussi le chemin reduced-motion).
  Widget host(Widget child) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  EvalVm evalVm(String id, String nom, EvalState state) => EvalVm(
    id: id,
    type: TypeEvaluation.interro,
    nom: nom,
    chapitres: const [],
    date: DateTime(2026, 5, 12),
    maxPoints: 10,
    poids: 1,
    state: state,
    pourcentageSaisie: state == EvalState.complete ? 100 : 30,
    saisies: state == EvalState.complete ? 10 : 3,
    total: 10,
  );

  BucketVm buildBucket() => BucketVm(
    key: 'sp:1',
    kind: BucketKind.sousPeriode,
    ordre: 2,
    statut: BucketStatut.current,
    evaluations: [
      evalVm('e1', 'Interro 1 — Nombres', EvalState.complete),
      evalVm('e2', 'Devoir 2 — Géométrie', EvalState.partial),
    ],
    moyenneClasse: 64,
    nombreElevesNotes: 18,
    nombreEleves50: 14,
    moyennesEleves: const [
      MoyenneEleve(
        studentId: 's1',
        firstName: 'Daniella',
        lastName: 'Kabongo',
        middleName: 'Nkosi',
        moyenne: 85,
      ),
      MoyenneEleve(
        studentId: 's2',
        firstName: 'Béni',
        lastName: 'Mbala',
        middleName: 'Mavinga',
        moyenne: 52,
      ),
      MoyenneEleve(
        studentId: 's3',
        firstName: 'Inès',
        lastName: 'Zola',
        middleName: null,
        moyenne: null,
      ),
    ],
    supportsReleve: true,
    saisiesNotes: 13,
    totalNotes: 20,
  );

  testWidgets(
    'panneau : rend la liste d\'évaluations et le bouton « Par élève »',
    (tester) async {
      await tester.pumpWidget(
        host(CoursBucketPanel(bucket: buildBucket(), onOpenReleve: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Interro 1 — Nombres'), findsOneWidget);
      expect(find.text('Devoir 2 — Géométrie'), findsOneWidget);
      expect(find.text('Par élève'), findsOneWidget);
      // Badges de statut.
      expect(find.text('Notée'), findsOneWidget);
    },
  );

  testWidgets('« Par élève » ouvre le relevé, trié par classement', (
    tester,
  ) async {
    final bucket = buildBucket();
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => CoursBucketPanel(
            bucket: bucket,
            onOpenReleve: () => showCoursReleveModal(
              context,
              brancheNom: 'Mathématiques',
              classroomName: '7e CTEB A',
              label: 'Sous-période 2',
              bucket: bucket,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Par élève'));
    await tester.pumpAndSettle();

    // Le relevé est ouvert : tri segmenté + élèves + pastille de %.
    expect(find.text('Classement'), findsOneWidget);
    expect(find.text('Alphabétique'), findsOneWidget);
    expect(find.text('Kabongo Nkosi'), findsOneWidget);
    expect(find.text('85 %'), findsOneWidget);
    // Élève non évalué -> pastille « — ».
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('bucket vide -> note inline « à venir »', (tester) async {
    const empty = BucketVm(
      key: 'sp:x',
      kind: BucketKind.sousPeriode,
      ordre: 1,
      statut: BucketStatut.upcoming,
      evaluations: [],
      moyenneClasse: null,
      nombreElevesNotes: 0,
      nombreEleves50: 0,
      moyennesEleves: [],
      supportsReleve: true,
      saisiesNotes: 0,
      totalNotes: 0,
    );
    await tester.pumpWidget(
      host(CoursBucketPanel(bucket: empty, onOpenReleve: () {})),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.text(l10n.courseDetailBucketEmptyUpcoming), findsOneWidget);
    // Pas de bouton « Par élève » sans moyennes d'élèves.
    expect(find.text('Par élève'), findsNothing);
  });
}
