import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_empty_states.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// **La sortie des états vides — et à qui elle est offerte.**
void main() {
  Future<Uri?> pump(
    WidgetTester tester,
    Widget child, {
    List<String>? permissions = const ['finance.charge.read'],
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final auth = _MockAuthBloc();
    final state = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => auth.state).thenReturn(state);
    whenListen(auth, Stream<AuthState>.value(state), initialState: state);

    Uri? landed;
    final router = GoRouter(
      initialLocation: '/till',
      routes: [
        GoRoute(
          path: '/till',
          builder: (context, _) => Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<AuthBloc>.value(value: auth, child: child),
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

  Widget globalEmpty({String period = 'day'}) => FinanceTillGlobalEmpty(
    windowLabel: 'Aujourd\'hui',
    period: period,
    onWindowRequested: (_) {},
  );

  testWidgets('« Ouvrir la facturation » mène à la coquille, pas hors d’elle', (
    tester,
  ) async {
    await pump(tester, globalEmpty());

    await tester.tap(find.text('Ouvrir la facturation'));
    await tester.pumpAndSettle();

    expect(find.text('coquille'), findsOneWidget);
  });

  testWidgets('la disjonction suffit — finance.payment.read ouvre aussi', (
    tester,
  ) async {
    await pump(
      tester,
      globalEmpty(),
      permissions: const ['finance.payment.read'],
    );

    // Le secrétariat n'a que les créances, le caissier que les paiements : leur
    // fermer l'écran à l'un ou l'autre retirerait une lecture détenue.
    expect(find.text('Ouvrir la facturation'), findsOneWidget);
  });

  testWidgets('sans droit sur la facturation, la porte ne s’annonce pas', (
    tester,
  ) async {
    await pump(
      tester,
      globalEmpty(),
      permissions: const ['finance.stats.read'],
    );

    // Un état vide dont la seule issue mène à un refus est pire qu'un état
    // vide sans issue.
    expect(find.text('Ouvrir la facturation'), findsNothing);
    // L'élargissement, lui, ne dépend d'aucun droit : il reste offert.
    expect(find.text('Voir ce mois'), findsOneWidget);
  });

  testWidgets('quand les deux issues manquent, la carte tient quand même', (
    tester,
  ) async {
    // Plage libre — pas d'élargissement — et pas de droit sur la facturation.
    //
    // ⚠️ La carte n'a alors AUCUNE action. La règle « jamais d'écran vide sans
    // issue » se tient au niveau de l'ÉCRAN et non de la carte : la fenêtre de
    // temps reste rendue au-dessus, et c'est elle qui reste l'issue. Les
    // actions de la carte en sont le raccourci, pas la seule voie.
    await pump(
      tester,
      globalEmpty(period: 'custom'),
      permissions: const ['finance.stats.read'],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Aucun encaissement · aujourd\'hui'), findsOneWidget);
  });

  testWidgets('le vide de caisse mène aussi à la facturation', (tester) async {
    await pump(
      tester,
      FinanceTillCurrencyEmpty(
        selected: const TillCurrencyBlock(
          currency: 'CDF',
          summary: TillSummary(
            total: 0,
            fees: 0,
            boutique: 0,
            receiptCount: 0,
            averageTicket: 0,
          ),
          buckets: [],
          byClassroom: [],
        ),
        others: const [
          TillCurrencyBlock(
            currency: 'USD',
            summary: TillSummary(
              total: 412000,
              fees: 412000,
              boutique: 0,
              receiptCount: 4,
              averageTicket: 103000,
            ),
            buckets: [],
            byClassroom: [],
          ),
        ],
        windowLabel: 'Aujourd\'hui',
        onCurrencySelected: (_) {},
      ),
    );

    expect(find.text('Caisse francs vide sur cette période'), findsOneWidget);
    expect(find.text('Voir la caisse dollars'), findsOneWidget);
    expect(find.text('Ouvrir la facturation'), findsOneWidget);
  });
}
