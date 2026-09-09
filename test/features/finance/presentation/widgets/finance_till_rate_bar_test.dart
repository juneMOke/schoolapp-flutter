import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/exchange_rates_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_rate_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockRatesCubit extends MockCubit<ExchangeRatesState>
    implements ExchangeRatesCubit {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

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

  /// Le harnais nomme une route `home` : c'est là que pointe « Modifier le
  /// taux », par le paramètre `subMenuId` de la coquille.
  Future<Uri?> pump(
    WidgetTester tester,
    ExchangeRatesState state, {
    List<String>? permissions = const ['school.provisioning.write'],
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

    final auth = _MockAuthBloc();
    final authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => auth.state).thenReturn(authState);
    whenListen(
      auth,
      Stream<AuthState>.value(authState),
      initialState: authState,
    );

    Uri? landed;
    final router = GoRouter(
      initialLocation: '/finances',
      routes: [
        GoRoute(
          path: '/finances',
          builder: (context, state) => Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<ExchangeRatesCubit>.value(value: rates),
                BlocProvider<AuthBloc>.value(value: auth),
              ],
              child: const FinanceTillRateBar(),
            ),
          ),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) {
            landed = state.uri;
            return const Scaffold(body: Text('coquille'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    return landed;
  }

  String? rateText(WidgetTester tester) {
    final texts = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .whereType<String>()
        // Les espaces insécables du formatage monétaire ne se tapent pas dans
        // une assertion.
        .map((t) => t.replaceAll(' ', ' '))
        .toList();
    return texts.where((t) => t.startsWith('1 ')).firstOrNull;
  }

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
    expect(find.text('Modifier le taux'), findsOneWidget);
  });

  testWidgets('sans taux paramétré, le bandeau reste — avec sa sortie', (
    tester,
  ) async {
    await pump(tester, const ExchangeRatesState(loaded: true));

    expect(find.text('Aucun taux paramétré'), findsOneWidget);
    // C'est par ce lien qu'on répare l'absence : le masquer laisserait un
    // constat sans issue.
    expect(find.text('Modifier le taux'), findsOneWidget);
  });

  testWidgets('tant que la série n’a pas répondu, rien n’est affirmé', (
    tester,
  ) async {
    await pump(tester, const ExchangeRatesState());

    expect(find.text('Aucun taux paramétré'), findsNothing);
    expect(find.text('Modifier le taux'), findsNothing);
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

  testWidgets('deux paires en vigueur se lisent toutes les deux', (
    tester,
  ) async {
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

    // En taire une serait le genre de silence que cet écran refuse partout
    // ailleurs.
    expect(
      find.textContaining('2 850,00'.replaceAll(' ', ' ')),
      findsOneWidget,
    );
    expect(
      find.textContaining('3 100,00'.replaceAll(' ', ' ')),
      findsOneWidget,
    );
  });

  testWidgets('« Modifier le taux » ouvre Réglages dans la coquille', (
    tester,
  ) async {
    await pump(
      tester,
      ExchangeRatesState(
        loaded: true,
        rates: [_rate('USD', 'CDF', 2850000000)],
      ),
    );

    await tester.tap(find.text('Modifier le taux'));
    await tester.pumpAndSettle();

    expect(find.text('coquille'), findsOneWidget);
  });

  testWidgets('sans le droit de configurer, le lien n’est pas offert', (
    tester,
  ) async {
    await pump(
      tester,
      ExchangeRatesState(
        loaded: true,
        rates: [_rate('USD', 'CDF', 2850000000)],
      ),
      permissions: const ['finance.stats.read'],
    );

    // Masqué et non grisé : un lien absent dit « pas vous », un lien estompé
    // dirait « pas maintenant ».
    expect(find.text('Modifier le taux'), findsNothing);
    // Le taux, lui, reste lisible — il n'est pas une action.
    expect(rateText(tester), '1 \$ = 2 850,00 FC');
  });

  testWidgets('à l’étroit, le lien passe sous le taux et le médaillon reste', (
    tester,
  ) async {
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
