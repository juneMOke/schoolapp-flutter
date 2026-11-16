import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/core/navigation/location_query.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_reports_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/treasury_evolution_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_location.dart';

/// Les valeurs de [keys] dans l'adresse de l'écran ; toutes `null` sans
/// routeur, ou pour un écran poussé par-dessus une autre page.
Map<String, String?> treasuryLocationOf(
  BuildContext context,
  Iterable<String> keys,
) {
  final router = LocationQuery.ownedBy(context);
  return {
    for (final key in keys)
      key: router == null ? null : LocationQuery.read(router, key),
  };
}

/// La journée de l'adresse de Clôture (`?jour=…`), `null` pour aujourd'hui.
DateTime? closingDayOf(BuildContext context) => TreasuryLocation.dayOf(
  treasuryLocationOf(context, const [
    TreasuryLocation.dayParam,
  ])[TreasuryLocation.dayParam],
);

/// La période de l'évolution (A3) tenue dans l'adresse. Il lance aussi la
/// première lecture, directement sur l'adresse (F5, lien) : une seule
/// requête au montage, pas la période par défaut puis celle de l'adresse.
class EvolutionLocationSync extends StatefulWidget {
  final Widget child;

  const EvolutionLocationSync({super.key, required this.child});

  @override
  State<EvolutionLocationSync> createState() => _EvolutionLocationSyncState();
}

class _EvolutionLocationSyncState extends State<EvolutionLocationSync> {
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final location = treasuryLocationOf(context, const [
      TreasuryLocation.evolutionParam,
      TreasuryLocation.evolutionFromParam,
      TreasuryLocation.evolutionToParam,
    ]);
    final cubit = context.read<TreasuryEvolutionCubit>();
    location.values.every((value) => value == null)
        ? cubit.load()
        : _apply(cubit, location);
  }

  static Future<void> _apply(
    TreasuryEvolutionCubit cubit,
    Map<String, String?> read,
  ) => cubit.applyLocation(
    TreasuryLocation.evolutionOf(read[TreasuryLocation.evolutionParam]),
    from: TreasuryLocation.dayOf(read[TreasuryLocation.evolutionFromParam]),
    to: TreasuryLocation.dayOf(read[TreasuryLocation.evolutionToParam]),
  );

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
              _apply(context.read<TreasuryEvolutionCubit>(), read),
          child: widget.child,
        ),
      );
}

/// Le type de rapports (A5) et leur page tenus dans l'adresse. Les rapports
/// « Période » générés pendant la session n'y vont pas. Il lance aussi la
/// première lecture, directement sur le type et la page de l'adresse.
class ReportsLocationSync extends StatefulWidget {
  final Widget child;

  const ReportsLocationSync({super.key, required this.child});

  @override
  State<ReportsLocationSync> createState() => _ReportsLocationSyncState();
}

class _ReportsLocationSyncState extends State<ReportsLocationSync> {
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final location = treasuryLocationOf(context, const [
      TreasuryLocation.reportsParam,
      TreasuryLocation.reportsPageParam,
    ]);
    final cubit = context.read<CashReportsCubit>();
    location.values.every((value) => value == null)
        ? cubit.load()
        : _apply(cubit, location);
  }

  static Future<void> _apply(
    CashReportsCubit cubit,
    Map<String, String?> read,
  ) => cubit.applyLocation(
    TreasuryLocation.reportKindOf(read[TreasuryLocation.reportsParam]),
    TreasuryLocation.pageOf(read[TreasuryLocation.reportsPageParam]),
  );

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
          onLocation: (read) => _apply(context.read<CashReportsCubit>(), read),
          child: widget.child,
        ),
      );
}
