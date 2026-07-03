import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_eleve_ligne.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_sous_periode.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultats_classe.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultats_classe_stats.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/sous_periode_colonne.dart';
import 'package:school_app_flutter/features/resultats/presentation/widgets/classe/resultats_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

ResultatsClasse _fixture() => const ResultatsClasse(
  classroomId: 'c1',
  periodeScolaireId: 'p1',
  periodeOrdre: 1,
  sousPeriodes: [
    SousPeriodeColonne(
      sousPeriodeId: 'sp1',
      ordre: 1,
      statut: StatutPeriode.cloturee,
    ),
    SousPeriodeColonne(
      sousPeriodeId: 'sp2',
      ordre: 2,
      statut: StatutPeriode.ouverte,
    ),
  ],
  stats: ResultatsClasseStats(
    effectif: 2,
    seuil: 50,
    moyenneClasse: 65,
    reussites: 1,
    echecs: 0,
    nonClasses: 1,
  ),
  lignes: [
    ResultatEleveLigne(
      rang: 1,
      studentId: 's-alice',
      nom: 'Zoe',
      prenom: 'Alice',
      nonClasse: false,
      moyenneGroupe: 82,
      pourcentages: [
        ResultatSousPeriode(sousPeriodeId: 'sp1', pourcentage: 80),
        ResultatSousPeriode(sousPeriodeId: 'sp2', pourcentage: 84),
      ],
    ),
    ResultatEleveLigne(
      studentId: 's-bob',
      nom: 'Adam',
      prenom: 'Bob',
      nonClasse: true,
      pourcentages: [
        ResultatSousPeriode(sousPeriodeId: 'sp1'),
        ResultatSousPeriode(sousPeriodeId: 'sp2'),
      ],
    ),
  ],
);

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (ctx) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(disableAnimations: true),
      child: Scaffold(
        body: SingleChildScrollView(child: SizedBox(width: 900, child: child)),
      ),
    ),
  ),
);

void main() {
  testWidgets('affiche les lignes + badge « Non classé »', (tester) async {
    await tester.pumpWidget(
      _host(
        ResultatsTable(
          resultats: _fixture(),
          periodeShortLabel: 'T1',
          classroomLabel: '7e A',
          onOpenLigne: (_) {},
        ),
      ),
    );

    expect(find.text('Alice Zoe'), findsOneWidget);
    expect(find.text('Bob Adam'), findsOneWidget);
    expect(find.text('Non classé'), findsOneWidget);
    expect(find.text('82 %'), findsOneWidget);
  });

  testWidgets('clic ligne classée → onOpenLigne ; non classé non cliquable', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(
      _host(
        ResultatsTable(
          resultats: _fixture(),
          periodeShortLabel: 'T1',
          classroomLabel: '7e A',
          onOpenLigne: (ligne) => opened.add(ligne.studentId),
        ),
      ),
    );

    await tester.tap(find.text('Alice Zoe'));
    await tester.pump();
    expect(opened, ['s-alice']);

    await tester.tap(find.text('Bob Adam'));
    await tester.pump();
    expect(opened, ['s-alice'], reason: 'la ligne non classée ne navigue pas');
  });
}
