import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/fee_control_situation_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **Situation recherchée** : cinq segments exclusifs. Le cinquième, « A payé
/// au moins… », est un seuil saisi dans UNE devise — il est désactivé quand
/// la classe en porte deux, avec sa raison en info-bulle (spec v2, R3).
void main() {
  late List<FeeControlPaymentFilter> picked;
  late TextEditingController controller;

  setUp(() {
    picked = [];
    controller = TextEditingController();
  });

  tearDown(() => controller.dispose());

  /// Les propriétés sémantiques du segment qui porte [label].
  SemanticsProperties segmentSemantics(WidgetTester tester, String label) =>
      tester
          .widget<Semantics>(
            find.ancestor(
              of: find.text(label),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Semantics &&
                    w.properties.inMutuallyExclusiveGroup == true,
              ),
            ),
          )
          .properties;

  Future<void> pump(
    WidgetTester tester, {
    required bool atLeastAvailable,
    FeeControlPaymentFilter selected = FeeControlPaymentFilter.all,
  }) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FeeControlSituationCard(
            selected: selected,
            counts: const FeeControlBreakdown(settled: 3, partial: 2, none: 5),
            currency: atLeastAvailable ? 'USD' : null,
            atLeastAvailable: atLeastAvailable,
            thresholdController: controller,
            onChanged: picked.add,
            onThresholdChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('les segments portent leur compteur — « Tous » compte la '
      'classe entière', (tester) async {
    await pump(tester, atLeastAvailable: true);

    expect(find.text('Tous'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('une seule devise : « a payé au moins… » se choisit', (
    tester,
  ) async {
    await pump(tester, atLeastAvailable: true);

    await tester.tap(find.text('A payé au moins…'));
    await tester.pumpAndSettle();

    expect(picked, [FeeControlPaymentFilter.threshold]);
    expect(
      find.byTooltip('Indisponible : francs et dollars cochés ensemble'),
      findsNothing,
    );
  });

  testWidgets('deux devises : « a payé au moins… » est désactivé, et dit '
      'pourquoi', (tester) async {
    await pump(tester, atLeastAvailable: false);

    await tester.tap(find.text('A payé au moins…'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Un seuil en dollars ne se compare pas à un payé en francs : le geste ne
    // part pas.
    expect(picked, isEmpty);
    expect(
      find.byTooltip('Indisponible : francs et dollars cochés ensemble'),
      findsOneWidget,
    );
    // L'assistance vocale l'annonce indisponible, pas seulement grisé.
    expect(segmentSemantics(tester, 'A payé au moins…').enabled, isFalse);
    expect(segmentSemantics(tester, 'Tous').enabled, isTrue);
  });

  testWidgets('deux devises : les quatre autres segments restent offerts', (
    tester,
  ) async {
    await pump(tester, atLeastAvailable: false);

    await tester.tap(find.text('Partiel'));
    await tester.pumpAndSettle();

    expect(picked, [FeeControlPaymentFilter.partial]);
  });

  testWidgets('le segment « a payé au moins… » choisi ouvre son montant', (
    tester,
  ) async {
    await pump(
      tester,
      atLeastAvailable: true,
      selected: FeeControlPaymentFilter.threshold,
    );

    expect(find.byType(TextField), findsOneWidget);
  });
}
