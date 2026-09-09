import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/exchange_rates_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_rate_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockRatesCubit extends MockCubit<ExchangeRatesState>
    implements ExchangeRatesCubit {}

ExchangeRate _rate(String base, String quote, int micros, {DateTime? from}) =>
    ExchangeRate(
      base: base,
      quote: quote,
      rateMicros: micros,
      effectiveFrom: from ?? DateTime.utc(2020),
    );

/// Le taux du jour tel qu'il se lit — **et ce qu'il ne prétend pas être.**
void main() {
  late _MockRatesCubit rates;

  setUp(() => rates = _MockRatesCubit());

  Future<void> pump(
    WidgetTester tester,
    ExchangeRatesState state, {
    Size size = const Size(1280, 800),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    when(() => rates.state).thenReturn(state);
    whenListen(
      rates,
      Stream<ExchangeRatesState>.value(state),
      initialState: state,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<ExchangeRatesCubit>.value(
            value: rates,
            child: const FinanceTillRateBar(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Les textes rendus, **espaces normalisés**.
  ///
  /// Le formatage monétaire pose des espaces insécables (`U+00A0`, `U+202F`)
  /// qu'on ne peut ni taper ni relire dans une assertion — et qui disparaissent
  /// silencieusement au premier copier-coller du fichier. `\s` les couvre tous.
  List<String> texts(WidgetTester tester) => find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .whereType<String>()
      .map((t) => t.replaceAll(RegExp(r'\s+'), ' '))
      .toList();

  String? rateText(WidgetTester tester) =>
      texts(tester).where((t) => t.startsWith('1 ')).firstOrNull;

  testWidgets('le taux en vigueur se lit « 1 \$ = 2 850,00 FC »', (
    tester,
  ) async {
    await pump(
      tester,
      ExchangeRatesState(
        loaded: true,
        rates: [_rate('USD', 'CDF', 2850000000)],
      ),
    );

    expect(rateText(tester), '1 \$ = 2 850,00 FC');
    // Deux décimales, contre les « 2 850 » de la maquette : une seule façon
    // d'écrire un taux dans l'application, partagée avec le ticket.
  });

  testWidgets('aucune sortie n’est offerte depuis le bandeau', (tester) async {
    await pump(
      tester,
      ExchangeRatesState(
        loaded: true,
        rates: [_rate('USD', 'CDF', 2850000000)],
      ),
    );

    // Arbitrage du porteur : le taux se change en Configuration ▸ Réglages, et
    // le bandeau redevient une lecture — comme toutes les cartes de cet écran,
    // dont aucune n'expose de bouton.
    expect(find.text('Modifier le taux'), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('sans taux paramétré, le bandeau reste — et le dit', (
    tester,
  ) async {
    await pump(tester, const ExchangeRatesState(loaded: true));

    expect(find.text('Aucun taux paramétré'), findsOneWidget);
    // Un constat désormais sans issue offerte : c'est le prix, connu, du lien
    // retiré.
    expect(find.text('Modifier le taux'), findsNothing);
  });

  testWidgets('tant que la série n’a pas répondu, rien n’est affirmé', (
    tester,
  ) async {
    await pump(tester, const ExchangeRatesState());

    expect(find.text('Aucun taux paramétré'), findsNothing);
    expect(rateText(tester), isNull);
  });

  testWidgets('l’identité n’est pas un taux à afficher', (tester) async {
    // La table en contient par construction : « il n'y a pas de "pas de taux",
    // il y a un taux de 1 ».
    await pump(
      tester,
      ExchangeRatesState(
        loaded: true,
        rates: [ExchangeRate.identity('USD'), ExchangeRate.identity('CDF')],
      ),
    );

    expect(find.text('Aucun taux paramétré'), findsOneWidget);
  });

  testWidgets('un taux qui ne prend effet que demain n’est pas en vigueur', (
    tester,
  ) async {
    await pump(
      tester,
      ExchangeRatesState(
        loaded: true,
        rates: [
          _rate(
            'USD',
            'CDF',
            2850000000,
            from: DateTime.now().toUtc().add(const Duration(days: 1)),
          ),
        ],
      ),
    );

    // Pas de repli sur le plus ancien : cet écran de direction dit la vérité
    // stricte, là où le guichet, lui, a besoin du repli pour ne pas inventer.
    expect(find.text('Aucun taux paramétré'), findsOneWidget);
  });

  testWidgets('le palier le plus récent l’emporte sur le précédent', (
    tester,
  ) async {
    await pump(
      tester,
      ExchangeRatesState(
        loaded: true,
        rates: [
          _rate('USD', 'CDF', 2700000000, from: DateTime.utc(2026, 1, 1)),
          _rate('USD', 'CDF', 2850000000, from: DateTime.utc(2026, 6, 1)),
        ],
      ),
    );

    expect(rateText(tester), '1 \$ = 2 850,00 FC');
  });

  testWidgets('une autre paire en vigueur n’est pas écrite', (tester) async {
    await pump(
      tester,
      ExchangeRatesState(
        loaded: true,
        rates: [
          _rate('USD', 'CDF', 2850000000),
          _rate('EUR', 'CDF', 3100000000),
        ],
      ),
    );

    // Le bandeau ne porte plus que le dollar contre le franc : c'est la paire
    // qui croise sur cet écran, et une paire exotique n'y expliquerait aucune
    // ligne de la table.
    expect(rateText(tester), '1 \$ = 2 850,00 FC');
    expect(
      texts(tester).where((t) => t.contains('3 100')),
      isEmpty,
      reason: 'l’euro n’explique aucune ligne de cet écran',
    );
  });

  testWidgets('une école qui n’a que l’euro ne voit aucun taux', (
    tester,
  ) async {
    await pump(
      tester,
      ExchangeRatesState(
        loaded: true,
        rates: [_rate('EUR', 'CDF', 3100000000)],
      ),
    );

    expect(find.text('Aucun taux paramétré'), findsOneWidget);
  });

  testWidgets('le sens inverse n’est pas retourné pour faire nombre', (
    tester,
  ) async {
    await pump(
      tester,
      ExchangeRatesState(loaded: true, rates: [_rate('CDF', 'USD', 350)]),
    );

    // L'inverse d'un taux arrondi n'est pas le taux inverse — et ce nombre
    // s'imprime sur les tickets.
    expect(find.text('Aucun taux paramétré'), findsOneWidget);
  });

  testWidgets('à l’étroit, le médaillon garde sa taille', (tester) async {
    await pump(
      tester,
      ExchangeRatesState(
        loaded: true,
        rates: [_rate('USD', 'CDF', 2850000000)],
      ),
      size: const Size(360, 800),
    );

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
    final medallion = tester.getSize(
      find
          .ancestor(
            of: find.byIcon(Icons.repeat_rounded),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(medallion.width, 30);
  });
}
