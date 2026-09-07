import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/cycle_bar_chart.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_bar_rows.dart';
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

    // ─── Écart assumé à la spec (l.383) : le porteur produit ne veut plus
    // voir les jours sans données. Deux garde-fous encadrent le filtre.
    group('les buckets à zéro quittent l\'axe', () {
      EvolutionBucket bucket(String label, int value, {bool current = false}) =>
          EvolutionBucket(
            key: label,
            shortLabel: label,
            longLabel: label,
            value: value,
            isCurrent: current,
          );

      Widget paceOf(List<EvolutionBucket> buckets) => _host(
        EnrollmentPaceSection(
          evolution: EnrollmentEvolution(
            granularity: EvolutionGranularity.day,
            currentBucketIndex: 0,
            buckets: buckets,
          ),
        ),
      );

      testWidgets('un jour creux disparaît quand il reste de quoi lire', (
        tester,
      ) async {
        await tester.pumpWidget(
          paceOf([
            bucket('lun', 4),
            bucket('mar', 0),
            bucket('mer', 7),
            bucket('jeu', 0),
            bucket('ven', 3),
          ]),
        );
        await tester.pumpAndSettle();

        expect(find.text('lun'), findsOneWidget);
        expect(find.text('mer'), findsOneWidget);
        expect(find.text('ven'), findsOneWidget);
        expect(find.text('mar'), findsNothing);
        expect(find.text('jeu'), findsNothing);
      });

      testWidgets('le bucket EN COURS reste, même à zéro', (tester) async {
        // Sinon la fenêtre « Aujourd'hui » peut ne plus contenir aujourd'hui,
        // et le relief n'a plus de support.
        await tester.pumpWidget(
          paceOf([
            bucket('lun', 4),
            bucket('mar', 6),
            bucket('mer', 3),
            bucket('jeu', 0, current: true),
          ]),
        );
        await tester.pumpAndSettle();

        expect(find.text('jeu'), findsOneWidget);
      });

      testWidgets('sous trois barres, la fenêtre dense est rendue entière', (
        tester,
      ) async {
        // Spec l.350 : « jamais moins de trois barres ». Une barre seule ne se
        // lit pas comme un rythme.
        await tester.pumpWidget(
          paceOf([
            bucket('lun', 0),
            bucket('mar', 0),
            bucket('mer', 0),
            bucket('jeu', 0),
            bucket('ven', 9, current: true),
          ]),
        );
        await tester.pumpAndSettle();

        for (final label in ['lun', 'mar', 'mer', 'jeu', 'ven']) {
          expect(find.text(label), findsOneWidget);
        }
      });

      testWidgets('tout à zéro : une phrase, pas un axe vide', (tester) async {
        await tester.pumpWidget(
          paceOf([
            bucket('lun', 0),
            bucket('mar', 0, current: true),
            bucket('mer', 0),
          ]),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CycleBarChart), findsNothing);
        expect(find.text('lun'), findsNothing);
      });
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
      // La fenêtre n'est écrite QU'UNE fois, dans l'indice — plus de
      // sous-titre « du jour » qui la répéterait juste en dessous.
      expect(find.text('du jour'), findsNothing);
      expect(find.text('Sur les 4 inscrits du jour'), findsOneWidget);
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

    testWidgets('l\'indice dit sur COMBIEN d\'inscrits la barre répartit', (
      tester,
    ) async {
      // « 50 % de filles » sur quatre inscriptions ne se lit pas comme sur
      // quatre cents : l'indice donne le dénominateur.
      await tester.pumpWidget(
        _host(
          EnrollmentGenderSection(
            windowDistribution: _gender(female: 7, male: 7),
            headcount: _gender(female: 182, male: 181),
            isSingleDay: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sur les 14 inscrits du jour'), findsOneWidget);
    });

    testWidgets('l\'indice suit la fenêtre, jour ou période', (tester) async {
      await tester.pumpWidget(
        _host(
          EnrollmentGenderSection(
            windowDistribution: _gender(female: 3, male: 1),
            headcount: _gender(female: 182, male: 181),
            isSingleDay: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sur les 4 inscrits de la période'), findsOneWidget);
    });

    testWidgets('« par type » dit ce que la barre oppose', (tester) async {
      await tester.pumpWidget(
        _host(
          EnrollmentTypeSection(
            kpis: _kpis(total: 10, first: 6, re: 4, pre: 7),
            isSingleDay: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Extérieur contre cohorte déjà scolarisée'),
        findsOneWidget,
      );
      // La note de la spec, mot pour mot.
      expect(
        find.textContaining('Seules les premières inscriptions font croître'),
        findsOneWidget,
      );
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

    testWidgets('un cycle garde la MÊME teinte sur les deux cartes', (
      tester,
    ) async {
      // ⚠️ Le contrat ne met pas la même chose dans les deux champs : un
      // niveau porte le NOM de son cycle (`LevelStatDto` ← `group.name()`),
      // la carte « Par cycle » porte son CODE (`group.code()`). Colorer les
      // deux cartes sur ces deux chaînes donnait au même cycle deux teintes
      // différentes dès que code ≠ nom — c'est-à-dire le cas normal.
      //
      // La fixture le reproduit exprès : code « PRIM » (qui ne matche aucun
      // alias et part au repli), nom « Primaire » (qui matche).
      const distribution = CycleDistribution(
        cycles: [
          CycleStat(
            code: 'PRIM',
            label: 'Primaire',
            total: 30,
            levels: [
              LevelStat(
                id: 'p1',
                code: 'P1',
                label: '1re année',
                cycle: 'Primaire',
                value: 30,
              ),
            ],
          ),
          CycleStat(
            code: 'SEC',
            label: 'Secondaire',
            total: 12,
            levels: [
              LevelStat(
                id: 's1',
                code: 'S1',
                label: '1re secondaire',
                cycle: 'Secondaire',
                value: 12,
              ),
            ],
          ),
        ],
      );

      Map<String, Color> colorsOf(WidgetTester tester) => {
        for (final row
            in tester.widget<EteeloBarRows>(find.byType(EteeloBarRows)).rows)
          row.label: row.color,
      };

      await tester.pumpWidget(
        _host(
          const EnrollmentLevelSection(
            distribution: distribution,
            isSingleDay: false,
          ),
        ),
      );
      final byLevel = colorsOf(tester);

      await tester.pumpWidget(
        _host(const EnrollmentCycleSection(distribution: distribution)),
      );
      final byCycle = colorsOf(tester);

      expect(byLevel['1re année'], byCycle['Primaire']);
      expect(byLevel['1re secondaire'], byCycle['Secondaire']);
      // Et deux cycles distincts ne se confondent pas pour autant.
      expect(byCycle['Primaire'], isNot(byCycle['Secondaire']));
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
