import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_simulation_controls.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Régressions relevées à la **revue adversariale** du lot REC-9.
///
/// Chacune décrit un silence : un chiffre qui ne vise personne, un champ qui
/// affiche un montant que le calcul a oublié, un écran qui se vide sans un mot.
/// Aucune ne se voyait à l'usage nominal — d'où ces tests.
void main() {
  LocalRecoveryLine line(
    String studentId, {
    String currency = 'USD',
    int expected = 30000,
    int paid = 5000,
  }) => LocalRecoveryLine(
    schoolLevelId: 'lvl-1',
    studentId: studentId,
    charges: [
      RecoveryChargePosition(
        feeCode: 'TUITION',
        position: FeeChargePosition(
          currency: currency,
          expectedInCents: expected,
          paidMirrorInCents: paid,
          paidPendingInCents: 0,
        ),
      ),
    ],
  );

  final rate = ExchangeRate(
    base: 'USD',
    quote: 'CDF',
    rateMicros: 2850 * ExchangeRate.scale,
    effectiveFrom: DateTime.utc(2026, 9),
  );

  group('le taux arrivé APRÈS les lignes', () {
    test(
      'reposé, il rend au plancher les élèves qu\'il ne pouvait pas comparer',
      () {
        final cubit = RecouvrementSimulationCubit();
        addTearDown(cubit.close);

        // Le registre descend d'abord, la série de taux ensuite : c'est
        // l'ordre réel quand les deux cubits chargent en parallèle.
        cubit.setLines([
          line('usd', currency: 'USD', paid: 500),
          line('cdf', currency: 'CDF', expected: 5000000, paid: 3000000),
        ]);
        cubit.setCriterion(RecouvrementCriterion.belowThreshold);
        cubit.setThreshold(Money.parse(10000, 'USD'));

        expect(
          cubit.state.result.targeted,
          1,
          reason: 'sans cours, l\'élève en francs n\'est pas comparable',
        );

        // Le taux arrive.
        cubit.setLines([
          line('usd', currency: 'USD', paid: 500),
          line('cdf', currency: 'CDF', expected: 5000000, paid: 3000000),
        ], rate: rate);

        expect(
          cubit.state.result.targeted,
          2,
          reason:
              'un critère qui ne vise personne parce qu\'un cubit voisin '
              'a répondu plus tard est un silence, pas un arbitrage',
        );
      },
    );
  });

  group('le champ du plancher', () {
    testWidgets('se vide quand le critère OUBLIE le plancher', (tester) async {
      final cubit = RecouvrementSimulationCubit();
      addTearDown(cubit.close);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: _Host(cubit: cubit)),
        ),
      );
      await tester.pumpAndSettle();

      cubit.setCriterion(RecouvrementCriterion.belowThreshold);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '120');
      await tester.pumpAndSettle();
      expect(cubit.state.threshold, isNotNull);

      // On quitte le critère : le cubit oublie le plancher.
      cubit.setCriterion(RecouvrementCriterion.noPayment);
      await tester.pumpAndSettle();
      // …puis on y revient.
      cubit.setCriterion(RecouvrementCriterion.belowThreshold);
      await tester.pumpAndSettle();

      expect(
        find.text('120'),
        findsNothing,
        reason: 'le champ montrerait un montant que le calcul ne connaît plus',
      );
      expect(cubit.state.threshold, isNull);
    });
  });
}

/// Monte les seuls réglages, sans le tableau de bord : le champ du plancher n'a
/// besoin que du cubit de simulation et d'un état de tableau de bord — dont il
/// ne lit que la liste des devises.
class _Host extends StatelessWidget {
  final RecouvrementSimulationCubit cubit;

  const _Host({required this.cubit});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<RecouvrementSimulationCubit>.value(value: cubit),
      BlocProvider<RecouvrementDashboardBloc>.value(value: _StubDashboard()),
    ],
    child: const SingleChildScrollView(child: RecouvrementSimulationControls()),
  );
}

/// Tableau de bord muet : les réglages n'en lisent que `rates`, pour choisir la
/// devise du plancher et savoir si la sélection est mixte.
class _StubDashboard
    extends MockBloc<RecouvrementDashboardEvent, RecouvrementDashboardState>
    implements RecouvrementDashboardBloc {
  _StubDashboard() {
    whenListen(
      this,
      const Stream<RecouvrementDashboardState>.empty(),
      initialState: const RecouvrementDashboardState(
        status: EnrollmentLoadStatus.success,
      ),
    );
  }
}
