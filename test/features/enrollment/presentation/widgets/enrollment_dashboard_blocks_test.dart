import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_dashboard_kpi_band.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_headcount_banner.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_insights_section.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_pace_section.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_where_sections.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_who_sections.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Widget _host(Widget child, {double width = 1000}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('fr'),
  builder: (context, w) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: w!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

GenderDistribution _gender({required int female, required int male}) =>
    GenderDistribution(
      total: female + male,
      segments: [
        GenderSegment(
          code: GenderSegmentCode.female,
          value: female,
          percent: female + male == 0 ? 0 : (female * 100) ~/ (female + male),
        ),
        GenderSegment(
          code: GenderSegmentCode.male,
          value: male,
          percent: female + male == 0 ? 0 : (male * 100) ~/ (female + male),
        ),
      ],
    );

EnrollmentKpis _kpis({
  int total = 10,
  int first = 6,
  int re = 4,
  int pre = 0,
}) => EnrollmentKpis(
  totalEnrollments: KpiValue(value: total),
  firstEnrollments: KpiValue(
    value: first,
    percentOfTotal: total == 0 ? 0 : (first * 100) ~/ total,
  ),
  reEnrollments: KpiValue(
    value: re,
    percentOfTotal: total == 0 ? 0 : (re * 100) ~/ total,
  ),
  preEnrollments: KpiValue(value: pre),
  inProgress: const KpiValue(value: 0),
);

void main() {
  group('bandeau d\'effectif', () {
    testWidgets('affiche le total et dit ce qu\'il ne compte PAS', (
      tester,
    ) async {
      // Un effectif est le chiffre qu'une école cite à l'extérieur : s'il ne
      // dit pas ce qu'il exclut, il sera comparé à un registre qui compte
      // autre chose.
      await tester.pumpWidget(
        _host(
          EnrollmentHeadcountBanner(
            headcount: _gender(female: 182, male: 181),
            schoolYear: '2026-2027',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('363'), findsOneWidget);
      expect(
        find.textContaining('hors demandes en ligne non validées'),
        findsOneWidget,
      );
    });

    testWidgets('reste à zéro plutôt que de disparaître', (tester) async {
      // C'est le repère de lecture de l'écran : le retirer au moment où il n'y
      // a rien laisserait l'utilisateur sans point d'ancrage.
      await tester.pumpWidget(
        _host(
          EnrollmentHeadcountBanner(
            headcount: _gender(female: 0, male: 0),
            schoolYear: '2026-2027',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('groupe les milliers', (tester) async {
      await tester.pumpWidget(
        _host(
          EnrollmentHeadcountBanner(
            headcount: _gender(female: 700, male: 550),
            schoolYear: '2026-2027',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 250'), findsOneWidget);
    });
  });

  group('chiffres clés', () {
    testWidgets('quatre cartes, et PLUS de « Dossiers en cours »', (
      tester,
    ) async {
      // La carte a été retirée : depuis que l'effectif ne compte que les
      // dossiers terminés, sa prémisse est fausse.
      await tester.pumpWidget(
        _host(EnrollmentDashboardKpiBand(kpis: _kpis(), windowLabel: 'Année')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inscriptions · année'), findsOneWidget);
      expect(find.text('Premières inscriptions'), findsOneWidget);
      expect(find.text('Réinscriptions'), findsOneWidget);
      expect(find.text('Pré-inscriptions en attente'), findsOneWidget);
      expect(find.textContaining('En cours'), findsNothing);
    });

    testWidgets('un compteur à zéro le dit en toutes lettres', (tester) async {
      // « 0 % des inscriptions de la période » se lirait comme un résultat.
      await tester.pumpWidget(
        _host(
          EnrollmentDashboardKpiBand(
            kpis: _kpis(total: 5, first: 5, re: 0),
            windowLabel: 'Année',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aucune sur la période'), findsOneWidget);
      expect(find.text('Aucune demande en ligne à traiter'), findsOneWidget);
    });

    testWidgets('la note explique ce qu\'aucune carte ne dit seule', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(EnrollmentDashboardKpiBand(kpis: _kpis(), windowLabel: 'Année')),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('devient une première inscription'),
        findsOneWidget,
      );
    });
  });

  group('rythme', () {
    testWidgets('peint le libellé du SERVEUR, jamais la clé', (tester) async {
      // LE test de la régression : `out-of-axis-before` n'est pas une date, et
      // l'ancien code en dérivait un libellé d'axe (« fore »).
      await tester.pumpWidget(
        _host(
          const EnrollmentPaceSection(
            evolution: EnrollmentEvolution(
              granularity: EvolutionGranularity.month,
              currentBucketIndex: 1,
              buckets: [
                EvolutionBucket(
                  key: 'out-of-axis-before',
                  shortLabel: 'avant',
                  longLabel: 'Avant l\'axe',
                  value: 2,
                  isCurrent: false,
                ),
                EvolutionBucket(
                  key: '2026-09',
                  shortLabel: 'sept.',
                  longLabel: 'septembre 2026',
                  value: 14,
                  isCurrent: true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('avant'), findsOneWidget);
      expect(find.text('sept.'), findsOneWidget);
      expect(find.textContaining('fore'), findsNothing);
      expect(find.textContaining('out-of-axis'), findsNothing);
    });

    testWidgets('les barres à zéro sont conservées', (tester) async {
      // La trame de temps reste lisible : un jour creux se voit, il ne
      // disparaît pas de l'axe.
      await tester.pumpWidget(
        _host(
          const EnrollmentPaceSection(
            evolution: EnrollmentEvolution(
              granularity: EvolutionGranularity.day,
              currentBucketIndex: 1,
              buckets: [
                EvolutionBucket(
                  key: '2026-09-05',
                  shortLabel: '05/09',
                  longLabel: 'samedi 5 septembre',
                  value: 0,
                  isCurrent: false,
                ),
                EvolutionBucket(
                  key: '2026-09-06',
                  shortLabel: '06/09',
                  longLabel: 'dimanche 6 septembre',
                  value: 0,
                  isCurrent: true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('05/09'), findsOneWidget);
      expect(find.text('06/09'), findsOneWidget);
    });
  });

  group('qui', () {
    testWidgets('la note porte DEUX chiffres de parité', (tester) async {
      // La parité de la fenêtre seule se surinterprète : sur quatre
      // inscriptions, « 75 % de filles » ne dit rien de l'école.
      await tester.pumpWidget(
        _host(
          EnrollmentGenderSection(
            windowDistribution: _gender(female: 3, male: 1),
            headcount: _gender(female: 182, male: 181),
            isSingleDay: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('75 % de filles sur la fenêtre'),
        findsOneWidget,
      );
      expect(
        find.textContaining('50 % sur l\'effectif complet'),
        findsOneWidget,
      );
      expect(find.text('du jour'), findsOneWidget);
    });

    testWidgets('les pré-inscriptions sont exclues du bloc « par type »', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          EnrollmentTypeSection(
            kpis: _kpis(total: 10, first: 6, re: 4, pre: 7),
            isSingleDay: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Première inscription'), findsOneWidget);
      expect(find.text('Réinscription'), findsOneWidget);
      expect(find.textContaining('Pré-inscription'), findsNothing);
    });
  });

  group('où', () {
    CycleDistribution distribution({required List<int> values}) =>
        CycleDistribution(
          cycles: [
            CycleStat(
              code: 'PRIMARY',
              label: 'Primaire',
              total: values.fold(0, (a, b) => a + b),
              levels: [
                for (var i = 0; i < values.length; i++)
                  LevelStat(
                    id: 'lvl-$i',
                    code: 'P${i + 1}',
                    label: '${i + 1}re année',
                    cycle: 'PRIMARY',
                    value: values[i],
                  ),
              ],
            ),
          ],
        );

    testWidgets('les niveaux à zéro sont masqués et le compte l\'annonce', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          EnrollmentLevelSection(
            distribution: distribution(values: [30, 0, 12]),
            isSingleDay: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1re année'), findsOneWidget);
      expect(find.text('3re année'), findsOneWidget);
      expect(find.text('2re année'), findsNothing);
      expect(find.text('2 niveaux concernés'), findsOneWidget);
    });

    testWidgets('trié du plus gros au plus petit', (tester) async {
      await tester.pumpWidget(
        _host(
          EnrollmentLevelSection(
            distribution: distribution(values: [5, 40]),
            isSingleDay: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toList();
      expect(
        labels.indexOf('2re année'),
        lessThan(labels.indexOf('1re année')),
      );
    });

    testWidgets('aucun niveau : une note, et AUCUN bouton d\'export', (
      tester,
    ) async {
      // Un bouton PDF au-dessus d'une carte vide produirait une page blanche.
      await tester.pumpWidget(
        _host(
          EnrollmentLevelSection(
            distribution: distribution(values: [0, 0]),
            isSingleDay: false,
            exportActions: const [Text('PDF')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PDF'), findsNothing);
      expect(
        find.textContaining('Aucun niveau n\'a reçu d\'inscription'),
        findsOneWidget,
      );
    });

    testWidgets('un clic sur une ligne remonte le niveau', (tester) async {
      LevelStat? tapped;
      await tester.pumpWidget(
        _host(
          EnrollmentLevelSection(
            distribution: distribution(values: [30]),
            isSingleDay: false,
            onLevelTap: (level) => tapped = level,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('1re année'));
      expect(tapped?.id, 'lvl-0');
    });
  });

  group('lectures & alertes', () {
    EnrollmentStats stats({
      required List<EvolutionBucket> buckets,
      int pre = 0,
      GenderDistribution? headcount,
    }) => EnrollmentStats(
      context: StatsContext(
        schoolYear: '2026-2027',
        period: 'year',
        periodStart: DateTime(2026, 9),
        periodEnd: DateTime(2026, 9, 6),
        generatedAt: DateTime(2026, 9, 6),
      ),
      headcount: headcount ?? _gender(female: 182, male: 181),
      kpis: _kpis(pre: pre),
      evolution: EnrollmentEvolution(
        granularity: EvolutionGranularity.month,
        currentBucketIndex: 0,
        buckets: buckets,
      ),
      distributionByCycle: const CycleDistribution(cycles: []),
      distributionByGender: _gender(female: 5, male: 5),
    );

    testWidgets('aucune carte n\'est rendue pour remplir la ligne', (
      tester,
    ) async {
      // Série vide et aucune demande : seule la parité subsiste.
      await tester.pumpWidget(
        _host(EnrollmentInsightsSection(stats: stats(buckets: const []))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parité'), findsOneWidget);
      expect(find.textContaining('le plus fort'), findsNothing);
      expect(find.text('Demandes en ligne à traiter'), findsNothing);
    });

    testWidgets('le pic n\'apparaît que s\'il compte quelque chose', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          EnrollmentInsightsSection(
            stats: stats(
              buckets: const [
                EvolutionBucket(
                  key: '2026-09',
                  shortLabel: 'sept.',
                  longLabel: 'septembre 2026',
                  value: 0,
                  isCurrent: true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('le plus fort'), findsNothing);
    });

    testWidgets('le titre du pic suit le grain de la série', (tester) async {
      await tester.pumpWidget(
        _host(
          EnrollmentInsightsSection(
            stats: stats(
              buckets: const [
                EvolutionBucket(
                  key: '2026-09',
                  shortLabel: 'sept.',
                  longLabel: 'septembre 2026',
                  value: 14,
                  isCurrent: true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mois le plus fort'), findsOneWidget);
      expect(find.textContaining('septembre 2026'), findsOneWidget);
      expect(find.textContaining('14 élèves'), findsOneWidget);
    });

    testWidgets('les demandes en ligne n\'apparaissent que s\'il y en a', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          EnrollmentInsightsSection(
            stats: stats(buckets: const [], pre: 3),
            onOpenPreRegistrations: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Demandes en ligne à traiter'), findsOneWidget);
      expect(find.text('Ouvrir les pré-inscriptions'), findsOneWidget);
    });

    testWidgets('la parité commente sans juger, des deux côtés du seuil', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          EnrollmentInsightsSection(
            stats: stats(
              buckets: const [],
              headcount: _gender(female: 90, male: 10),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('penche d\'un côté'), findsOneWidget);
    });
  });
}
