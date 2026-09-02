import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_settlement_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le taux du jour, au-dessus des lignes de frais.
///
/// Deux propriétés portent la section : **le cas courant ne coûte rien** (aucune
/// paire convertie ⇒ rien à l'écran), et **le guichet propose** — le taux arrive
/// rempli, le corriger demande un geste, et l'écart se signale sans rien
/// bloquer.
final _rate = ExchangeRate(
  base: 'USD',
  quote: 'CDF',
  rateMicros: 1666670000,
  effectiveFrom: DateTime.utc(2026, 9, 1),
  divergenceBandBp: 200,
);

FacturationRatePair _pair({
  ExchangeRate? rate,
  ExchangeRate? referenceRate,
  bool editing = false,
  bool diverges = false,
  TextEditingController? controller,
  VoidCallback? onEdit,
}) => FacturationRatePair(
  rate: rate ?? _rate,
  referenceRate: referenceRate,
  controller: controller ?? TextEditingController(),
  editing: editing,
  onEdit: onEdit ?? () {},
  diverges: diverges,
);

Future<void> _pump(
  WidgetTester tester, {
  List<FacturationRatePair> pairs = const [],
  bool explainWhenUnavailable = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: TenderSettlementSection(
            pairs: pairs,
            explainWhenUnavailable: explainWhenUnavailable,
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('aucune conversion : la section n’existe pas', (tester) async {
    await _pump(tester);

    expect(find.byType(SizedBox), findsWidgets);
    expect(find.textContaining('Taux'), findsNothing);
  });

  testWidgets(
    'un frais coché sans aucun taux paramétré : on dit ce qui manque',
    (tester) async {
      // Éteindre en silence laisserait un écran où il ne se passe rien, et rien
      // ne distinguerait « cette école n'encaisse qu'en une monnaie » de « la
      // fonction est cassée ».
      await _pump(tester, explainWhenUnavailable: true);

      expect(find.byIcon(Icons.currency_exchange_rounded), findsOneWidget);
    },
  );

  testWidgets('le taux arrive rempli, en lecture', (tester) async {
    await _pump(tester, pairs: [_pair()]);

    expect(find.textContaining('666,67'), findsOneWidget);
    expect(find.text('Modifier'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('« Modifier » demande un geste explicite', (tester) async {
    var demande = false;
    await _pump(tester, pairs: [_pair(onEdit: () => demande = true)]);

    await tester.tap(find.text('Modifier'));
    await tester.pump();

    expect(demande, isTrue);
  });

  testWidgets('en saisie, le champ remplace la ligne de lecture', (
    tester,
  ) async {
    await _pump(tester, pairs: [_pair(editing: true)]);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Modifier'), findsNothing);
  });

  testWidgets('un taux hors bande avertit sans rien bloquer', (tester) async {
    await _pump(
      tester,
      pairs: [
        _pair(
          rate: ExchangeRate(
            base: 'USD',
            quote: 'CDF',
            rateMicros: 2000000000,
            effectiveFrom: DateTime.utc(2026, 9, 1),
          ),
          referenceRate: _rate,
          diverges: true,
        ),
      ],
    );

    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    // L'avertissement nomme le taux de l'école : sans lui, le caissier ne sait
    // pas de combien il s'écarte.
    expect(find.textContaining('666,67'), findsOneWidget);
  });

  testWidgets('sans divergence, aucun avertissement', (tester) async {
    await _pump(tester, pairs: [_pair(referenceRate: _rate)]);

    expect(find.byIcon(Icons.info_outline), findsNothing);
  });

  testWidgets('deux paires converties : deux taux, jamais fondus en un', (
    tester,
  ) async {
    await _pump(
      tester,
      pairs: [
        _pair(),
        _pair(
          rate: ExchangeRate(
            base: 'EUR',
            quote: 'CDF',
            rateMicros: 3000000000,
            effectiveFrom: DateTime.utc(2026, 9, 1),
          ),
        ),
      ],
    );

    expect(find.text('Modifier'), findsNWidgets(2));
    expect(find.textContaining('666,67'), findsOneWidget);
    expect(find.textContaining('000,00'), findsOneWidget);
  });
}
