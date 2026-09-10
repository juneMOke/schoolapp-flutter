import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_perimeter_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La carte de périmètre — et surtout sa **ligne de contexte**, où la note des
/// non-facturés a emménagé quand le bandeau de synthèse a laissé la place aux
/// quatre chiffres clés.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    int? concernedCount,
    int? unbilled,
    ExchangeRate? rate,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecouvrementPerimeterCard(
              feeCodes: const ['TUITION', 'BOOKS'],
              selectedFeeCodes: const {'TUITION'},
              cycles: const [],
              selectedCycleId: null,
              onFeeCodesChanged: (_) {},
              onCycleChanged: (_) {},
              concernedCount: concernedCount,
              unbilled: unbilled,
              exchangeRate: rate,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('la ligne de contexte', () {
    testWidgets('se tait tant qu\'aucune lecture n\'a abouti', (tester) async {
      await pump(tester, concernedCount: null);

      expect(
        find.textContaining('concernés'),
        findsNothing,
        reason:
            '« 0 élève concerné » avant d\'avoir lu serait un chiffre, pas '
            'une attente',
      );
    });

    testWidgets('annonce l\'effectif CONCERNÉ, pas l\'effectif inscrit', (
      tester,
    ) async {
      await pump(tester, concernedCount: 412);

      expect(find.textContaining('412'), findsOneWidget);
    });
  });

  group('la note des non-facturés', () {
    testWidgets('se lit à côté de l\'effectif, jamais dans le taux', (
      tester,
    ) async {
      await pump(tester, concernedCount: 400, unbilled: 12);

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(
        find.textContaining(l10n.recouvrementUnbilledNote(12)),
        findsOneWidget,
      );
    });

    testWidgets(
      'compte inconnu : la note se TAIT plutôt que d\'annoncer zéro',
      (tester) async {
        await pump(tester, concernedCount: 400, unbilled: null);

        expect(
          find.textContaining('ne portent aucun'),
          findsNothing,
          reason: '« on n\'a pas pu vérifier » n\'est pas « personne »',
        );
      },
    );

    testWidgets('zéro non-facturé : rien à signaler, rien d\'affiché', (
      tester,
    ) async {
      await pump(tester, concernedCount: 400, unbilled: 0);

      expect(find.textContaining('ne portent aucun'), findsNothing);
    });
  });

  group('le taux du jour', () {
    testWidgets('est rappelé quand l\'école en a posé un', (tester) async {
      await pump(
        tester,
        concernedCount: 400,
        rate: ExchangeRate(
          base: 'USD',
          quote: 'CDF',
          rateMicros: 2850 * ExchangeRate.scale,
          effectiveFrom: DateTime.utc(2026, 9, 1),
        ),
      );

      // Le taux s'écrit comme partout ailleurs — l'espace fine insécable de
      // `MoneyFormat` comprise. On vérifie qu'il est RAPPELÉ, pas qu'on sait le
      // réécrire à la main.
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      final rate = ExchangeRate(
        base: 'USD',
        quote: 'CDF',
        rateMicros: 2850 * ExchangeRate.scale,
        effectiveFrom: DateTime.utc(2026, 9, 1),
      );
      expect(
        find.textContaining(l10n.recouvrementRateLine(rate.formatted())),
        findsOneWidget,
      );
    });

    testWidgets('son absence se DIT — jamais un taux inventé', (tester) async {
      await pump(tester, concernedCount: 400, rate: null);

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.textContaining(l10n.recouvrementRateMissing), findsOneWidget);
    });
  });
}
