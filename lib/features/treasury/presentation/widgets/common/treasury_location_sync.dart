import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_reports_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/treasury_evolution_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_location.dart';

/// La période de l'évolution (A3) tenue dans l'adresse.
class EvolutionLocationSync extends StatelessWidget {
  final Widget child;

  const EvolutionLocationSync({super.key, required this.child});

  static (String?, String?, String?) _values(TreasuryEvolutionState state) {
    final custom = state.period == EvolutionPeriod.custom;
    return (
      state.period == TreasuryLocation.defaultEvolution
          ? null
          : state.period.name,
      custom ? TreasuryLocation.write(state.customFrom) : null,
      custom ? TreasuryLocation.write(state.customTo) : null,
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        TreasuryEvolutionCubit,
        TreasuryEvolutionState,
        (String?, String?, String?)
      >(
        selector: _values,
        builder: (context, values) => LocationParamsSync(
          current: {
            TreasuryLocation.evolutionParam: values.$1,
            TreasuryLocation.evolutionFromParam: values.$2,
            TreasuryLocation.evolutionToParam: values.$3,
          },
          onLocation: (read) =>
              context.read<TreasuryEvolutionCubit>().applyLocation(
                TreasuryLocation.evolutionOf(
                  read[TreasuryLocation.evolutionParam],
                ),
                from: TreasuryLocation.dayOf(
                  read[TreasuryLocation.evolutionFromParam],
                ),
                to: TreasuryLocation.dayOf(
                  read[TreasuryLocation.evolutionToParam],
                ),
              ),
          child: child,
        ),
      );
}

/// Le type de rapports (A5) et leur page tenus dans l'adresse. Les rapports
/// « Période » générés pendant la session n'y vont pas.
class ReportsLocationSync extends StatelessWidget {
  final Widget child;

  const ReportsLocationSync({super.key, required this.child});

  static (String?, String?) _values(CashReportsState state) => (
    state.kind == TreasuryLocation.defaultReportKind ? null : state.kind.name,
    state.kind == CashReportKind.period
        ? null
        : TreasuryLocation.writePage(state.requestedPage),
  );

  @override
  Widget build(BuildContext context) =>
      BlocSelector<CashReportsCubit, CashReportsState, (String?, String?)>(
        selector: _values,
        builder: (context, values) => LocationParamsSync(
          current: {
            TreasuryLocation.reportsParam: values.$1,
            TreasuryLocation.reportsPageParam: values.$2,
          },
          onLocation: (read) => context.read<CashReportsCubit>().applyLocation(
            TreasuryLocation.reportKindOf(read[TreasuryLocation.reportsParam]),
            TreasuryLocation.pageOf(read[TreasuryLocation.reportsPageParam]),
          ),
          child: child,
        ),
      );
}
