import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_dashboard_labels.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_fee_rates_section.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_insights_section.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_perimeter_card.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fiche/fee_control_fee_line.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/fee_control_fee_slot.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un frais, un nom — sur les deux écrans du module.
///
/// Chaque surface qui nomme une nature est éprouvée ici avec le MÊME catalogue :
/// l'école a renommé `TUITION` en « Frais scolaires annuels », et ce nom doit
/// apparaître partout où l'opérateur lit ce frais. C'est aussi celui que la
/// liste de relance imprime.
class _MockDashboardBloc
    extends MockBloc<RecouvrementDashboardEvent, RecouvrementDashboardState>
    implements RecouvrementDashboardBloc {}

const _title = 'Frais scolaires annuels';
const _titles = FeeSectionTitlesState(titles: {'TUITION': _title});

const _tariff = LocalFeeTariff(
  id: 't1',
  feeCode: 'TUITION',
  code: 'T1',
  label: 'Minerval 1ère année',
  amountInCents: 20000,
  currency: 'USD',
  schoolLevelId: 'l1',
);

const _group = RecouvrementCurrencyGroup(
  currency: 'USD',
  fees: [
    RecouvrementFeeRate(
      feeCode: 'TUITION',
      currency: 'USD',
      expectedInCents: 20000,
      paidInCents: 10000,
      remainingInCents: 10000,
    ),
  ],
  expectedInCents: 20000,
  paidInCents: 10000,
  remainingInCents: 10000,
);

_MockDashboardBloc _dashboard() {
  final bloc = _MockDashboardBloc();
  final state = RecouvrementDashboardState(
    status: EnrollmentLoadStatus.success,
    figures: RecouvrementKeyFigures(
      total: 2,
      none: 1,
      partial: 0,
      settled: 1,
      expected: MoneyBag.of([Money.parse(20000, 'USD')]),
      paid: MoneyBag.of([Money.parse(10000, 'USD')]),
      remaining: MoneyBag.of([Money.parse(10000, 'USD')]),
    ),
    rates: const [_group],
    lastQuery: const RecouvrementQuery(
      academicYearId: 'ay-1',
      feeCodes: ['TUITION'],
    ),
  );
  whenListen(
    bloc,
    const Stream<RecouvrementDashboardState>.empty(),
    initialState: state,
  );
  return bloc;
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  RecouvrementDashboardBloc? bloc,
}) async {
  final body = SingleChildScrollView(child: child);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: bloc == null
            ? body
            : MultiBlocProvider(
                providers: [
                  BlocProvider<RecouvrementDashboardBloc>.value(value: bloc),
                  BlocProvider<RecouvrementSimulationCubit>(
                    create: (_) => RecouvrementSimulationCubit(),
                  ),
                ],
                child: body,
              ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

FeeControlFeeSlot _slot({
  FeeSectionTitlesState titles = const FeeSectionTitlesState(),
}) => FeeControlFeeSlot(
  tariffs: const [_tariff],
  selected: const {'TUITION'},
  hasLevel: true,
  isLoading: false,
  feeGridMissing: false,
  loadFailed: false,
  onChanged: (_) {},
  onRetry: () {},
  sectionTitles: titles,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('le tableau de bord', () {
    testWidgets('frais retenus : la pastille porte le titre de l\'école', (
      tester,
    ) async {
      await _pump(
        tester,
        RecouvrementPerimeterCard(
          feeCodes: const ['TUITION'],
          selectedFeeCodes: const {'TUITION'},
          cycles: const [],
          selectedCycleId: null,
          onFeeCodesChanged: (_) {},
          onCycleChanged: (_) {},
          feeLabels: const {'TUITION': _title},
        ),
      );

      expect(find.text(_title), findsOneWidget);
    });

    testWidgets('taux par frais : le poste se nomme comme sa pastille', (
      tester,
    ) async {
      await _pump(
        tester,
        const RecouvrementFeeRatesSection(groups: [_group], titles: _titles),
        bloc: _dashboard(),
      );

      expect(find.text(_title), findsOneWidget);
    });

    testWidgets('taux par frais : sans catalogue, le titre n\'est pas '
        'inventé', (tester) async {
      await _pump(
        tester,
        const RecouvrementFeeRatesSection(groups: [_group]),
        bloc: _dashboard(),
      );

      expect(find.text(_title), findsNothing);
    });

    testWidgets('lectures : le poste le plus en retard se nomme par son '
        'titre', (tester) async {
      await _pump(
        tester,
        RecouvrementInsightsSection(
          labels: FeeControlDashboardLabels.from(const []),
          showCycleInLabels: true,
          titles: _titles,
        ),
        bloc: _dashboard(),
      );

      expect(find.textContaining(_title), findsOneWidget);
    });
  });

  group('l\'écran de contrôle', () {
    testWidgets('la pastille préfère le titre à la grille : le même nom qu\'au '
        'tableau de bord', (tester) async {
      await _pump(tester, _slot(titles: _titles));

      expect(find.text(_title), findsOneWidget);
      expect(find.text('Minerval 1ère année'), findsNothing);
    });

    testWidgets('sans titre sur l\'appareil, la grille nomme toujours', (
      tester,
    ) async {
      await _pump(tester, _slot());

      expect(find.text('Minerval 1ère année'), findsOneWidget);
    });

    testWidgets('les pastilles suivent l\'ordre que l\'école donne à ses '
        'sections', (tester) async {
      await _pump(
        tester,
        FeeControlFeeSlot(
          tariffs: const [
            _tariff,
            LocalFeeTariff(
              id: 't2',
              feeCode: 'REGISTRATION',
              label: 'Inscription',
              amountInCents: 1000,
              currency: 'USD',
              schoolLevelId: 'l1',
            ),
          ],
          selected: const {'TUITION'},
          hasLevel: true,
          isLoading: false,
          feeGridMissing: false,
          loadFailed: false,
          onChanged: (_) {},
          onRetry: () {},
          sectionTitles: const FeeSectionTitlesState(
            titles: {'REGISTRATION': 'Frais d\'inscription', 'TUITION': _title},
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.text('Frais d\'inscription')).dx,
        lessThan(tester.getTopLeft(find.text(_title)).dx),
      );
    });

    testWidgets('la fiche d\'un élève nomme le frais comme sa pastille', (
      tester,
    ) async {
      await _pump(
        tester,
        const FeeControlFeeLine(
          charge: RecoveryChargePosition(
            feeCode: 'TUITION',
            position: FeeChargePosition(
              currency: 'USD',
              expectedInCents: 20000,
              paidMirrorInCents: 5000,
              paidPendingInCents: 0,
            ),
          ),
          tariffs: [_tariff],
          rate: null,
          sectionTitles: _titles,
        ),
      );

      expect(find.text(_title), findsOneWidget);
    });
  });
}
