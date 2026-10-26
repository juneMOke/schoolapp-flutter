import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/navigation/bloc_location_tab.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';

enum _Tab { ledger, statement, history }

class _State {
  final _Tab tab;
  final String month;

  const _State(this.tab, this.month);
}

class _Cubit extends Cubit<_State> {
  _Cubit() : super(const _State(_Tab.ledger, '2026-10'));

  void setTab(_Tab tab) {
    if (tab != state.tab) emit(_State(tab, state.month));
  }

  void showMonth(String? month) {
    final wanted = month ?? '2026-10';
    if (wanted != state.month) emit(_State(state.tab, wanted));
  }

  /// Le geste de l'historique de la paie : le mois ET l'onglet d'un coup.
  void openMonth(String month) {
    if (month != state.month) emit(_State(state.tab, month));
    setTab(_Tab.ledger);
  }
}

/// Deux liens d'adresse sur la même page — l'onglet (`BlocLocationTab`) et le
/// mois (`LocationParamsSync`) : l'écriture du premier ne doit pas réveiller
/// le second sur l'ancienne valeur et défaire le geste.
void main() {
  Future<(_Cubit, GoRouter)> pump(WidgetTester tester, String location) async {
    late _Cubit cubit;
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/p',
          builder: (context, state) => BlocProvider(
            create: (_) => cubit = _Cubit(),
            child: BlocLocationTab<_Cubit, _State, _Tab>(
              values: _Tab.values,
              tabOf: (s) => s.tab,
              select: (c, t) => c.setTab(t),
              child: Builder(
                builder: (context) => BlocSelector<_Cubit, _State, String?>(
                  selector: (s) => s.month == '2026-10' ? null : s.month,
                  builder: (context, month) => LocationParamsSync(
                    current: {'mois': month},
                    onLocation: (v) =>
                        context.read<_Cubit>().showMonth(v['mois']),
                    child: const SizedBox(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return (cubit, router);
  }

  testWidgets('ouvrir un mois depuis un autre onglet garde le mois', (
    tester,
  ) async {
    final (cubit, router) = await pump(tester, '/p?onglet=history');
    expect(cubit.state.tab, _Tab.history);

    cubit.openMonth('2026-03');
    await tester.pumpAndSettle();

    expect(cubit.state.month, '2026-03');
    expect(cubit.state.tab, _Tab.ledger);
    final uri = router.routerDelegate.currentConfiguration.uri;
    expect(uri.queryParameters['mois'], '2026-03');
    expect(uri.queryParameters.containsKey('onglet'), isFalse);
  });

  testWidgets('d un mois d adresse à un autre, le dernier gagne', (
    tester,
  ) async {
    final (cubit, _) = await pump(tester, '/p?onglet=history&mois=2026-03');
    expect(cubit.state.month, '2026-03');

    cubit.openMonth('2026-05');
    await tester.pumpAndSettle();

    expect(cubit.state.month, '2026-05');
  });
}
