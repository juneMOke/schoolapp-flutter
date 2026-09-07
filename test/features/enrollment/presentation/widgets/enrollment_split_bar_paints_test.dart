import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_split_bar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_who_sections.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux barres « qui » **peignent-elles** ce qu'on leur donne ?
///
/// Le porteur produit voit les deux barres vides après reconstruction de
/// l'app. Ces tests répondent à la seule question qui soit du ressort du
/// client : alimentées avec des valeurs non nulles, les barres dessinent-elles
/// des segments larges ?
///
/// Si elles passent, le chemin de rendu est sain et un écran vide ne peut
/// venir que de données à zéro — donc de l'alimentation serveur, qu'aucune
/// correction d'affichage ne doit maquiller.
///
/// ⚠️ Les deux régimes d'animation sont éprouvés **séparément**, et c'est le
/// point : `EteeloSplitBar` interpole sa largeur de 0 à 1. Un test qui ne
/// couvrirait que `disableAnimations` verrait toujours l'état final et
/// laisserait passer une barre bloquée à t = 0 dans l'app réelle.
Widget _host(Widget child, {required bool animations}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('fr'),
  builder: (context, w) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: !animations),
    child: w!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(child: SizedBox(width: 900, child: child)),
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
  int total = 14,
  int first = 6,
  int re = 8,
  int inProgress = 0,
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
  preEnrollments: const KpiValue(value: 0),
  inProgress: KpiValue(value: inProgress),
);

/// Largeur peinte du segment de couleur [color].
///
/// La pastille de légende porte la même teinte mais dans un `Container`
/// décoré ; seul le segment de la barre est un `ColoredBox`. C'est donc bien
/// la barre qu'on mesure.
double _segmentWidth(WidgetTester tester, Color color) {
  final finder = find.byWidgetPredicate(
    (widget) => widget is ColoredBox && widget.color == color,
  );
  expect(finder, findsOneWidget, reason: 'segment $color absent de la barre');
  return tester.getSize(finder).width;
}

void main() {
  group('la barre filles/garçons peint ses segments', () {
    for (final animations in [false, true]) {
      testWidgets('animations=$animations', (tester) async {
        await tester.pumpWidget(
          _host(
            EnrollmentGenderSection(
              windowDistribution: _gender(female: 7, male: 7),
              headcount: _gender(female: 182, male: 181),
              isSingleDay: true,
            ),
            animations: animations,
          ),
        );
        await tester.pumpAndSettle();

        final girls = _segmentWidth(tester, AppColors.enrollmentStatsFemale);
        final boys = _segmentWidth(tester, AppColors.enrollmentStatsMale);

        expect(girls, greaterThan(0));
        expect(boys, greaterThan(0));
        // Parité stricte : les deux moitiés sont égales à l'arrondi près.
        expect(girls, closeTo(boys, 1.0));
      });
    }

    testWidgets('les largeurs suivent les proportions', (tester) async {
      await tester.pumpWidget(
        _host(
          EnrollmentGenderSection(
            windowDistribution: _gender(female: 9, male: 3),
            headcount: _gender(female: 182, male: 181),
            isSingleDay: false,
          ),
          animations: true,
        ),
      );
      await tester.pumpAndSettle();

      final girls = _segmentWidth(tester, AppColors.enrollmentStatsFemale);
      final boys = _segmentWidth(tester, AppColors.enrollmentStatsMale);

      expect(girls / boys, closeTo(3.0, 0.05));
    });
  });

  group('la barre « par type » peint ses segments', () {
    for (final animations in [false, true]) {
      testWidgets('animations=$animations', (tester) async {
        await tester.pumpWidget(
          _host(
            EnrollmentTypeSection(kpis: _kpis(), isSingleDay: false),
            animations: animations,
          ),
        );
        await tester.pumpAndSettle();

        final first = _segmentWidth(tester, AppColors.enrollmentStatsFirst);
        final re = _segmentWidth(tester, AppColors.enrollmentStatsRe);

        expect(first, greaterThan(0));
        expect(re, greaterThan(0));
        // 6 contre 8 : la réinscription est la part la plus large.
        expect(re, greaterThan(first));
      });
    }
  });

  // ─── Le profil d'une semaine de rentrée ───────────────────────────────
  //
  // Mesuré côté serveur : `distributionByGender`, `first`, `re` et `pre`
  // filtrent tous `status = COMPLETED` strict ; seul `kpis.total` compte
  // aussi les dossiers `IN_PROGRESS`. Une fenêtre dont les dossiers sont tous
  // en cours donne donc `total > 0` — l'écran s'affiche — avec TOUTES les
  // répartitions à zéro. Ce n'est pas un cas exotique : c'est ce que voit une
  // école en pleine campagne, au moment où elle consulte le plus.
  //
  // Deux pistes grises muettes sous une carte « Inscriptions » à 1 se lisent
  // alors comme une panne d'affichage — c'est exactement ce qui est arrivé.
  group('quand il n\'y a rien à répartir, la carte le DIT', () {
    testWidgets('filles/garçons nomme les dossiers en cours', (tester) async {
      await tester.pumpWidget(
        _host(
          EnrollmentGenderSection(
            windowDistribution: _gender(female: 0, male: 0),
            headcount: _gender(female: 182, male: 181),
            isSingleDay: true,
            inProgress: 14,
          ),
          animations: true,
        ),
      );
      await tester.pumpAndSettle();

      // Plus de piste muette : une phrase, et elle nomme ce qui EST là.
      expect(find.textContaining('14 dossiers sont en cours'), findsOneWidget);
      expect(
        find.textContaining('aucune inscription n\'est encore finalisée'),
        findsOneWidget,
      );
      // Surtout pas « aucune donnée » : la donnée existe, elle n'est pas
      // finalisée.
      expect(find.textContaining('Aucune donnée'), findsNothing);
    });

    testWidgets('« par type » dit la même chose, au même moment', (
      tester,
    ) async {
      // Les deux cartes rencontrent le même vide pour la même raison : elles
      // doivent le dire de la même façon.
      await tester.pumpWidget(
        _host(
          EnrollmentTypeSection(
            kpis: _kpis(total: 14, first: 0, re: 0, inProgress: 14),
            isSingleDay: false,
          ),
          animations: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('14 dossiers sont en cours'), findsOneWidget);
    });

    testWidgets('sans dossier en cours, la phrase reste juste', (tester) async {
      await tester.pumpWidget(
        _host(
          EnrollmentGenderSection(
            windowDistribution: _gender(female: 0, male: 0),
            headcount: _gender(female: 182, male: 181),
            isSingleDay: true,
          ),
          animations: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Aucune inscription finalisée'),
        findsOneWidget,
      );
      expect(find.textContaining('en cours'), findsNothing);
    });

    testWidgets('la barre disparaît, elle ne reste pas vide dessous', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          EnrollmentGenderSection(
            windowDistribution: _gender(female: 0, male: 0),
            headcount: _gender(female: 182, male: 181),
            isSingleDay: true,
            inProgress: 3,
          ),
          animations: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EteeloSplitBar), findsNothing);
    });

    testWidgets('un seul dossier en cours s\'accorde au singulier', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          EnrollmentTypeSection(
            kpis: _kpis(total: 1, first: 0, re: 0, inProgress: 1),
            isSingleDay: true,
          ),
          animations: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('1 dossier est en cours'), findsOneWidget);
    });
  });
}
