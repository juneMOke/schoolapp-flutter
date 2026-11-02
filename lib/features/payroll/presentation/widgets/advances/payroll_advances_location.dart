import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';

/// Le filtre des avances dans l'adresse : `?filtre=settled`. F5 le retrouve,
/// Précédent revient au filtre d'avant ; « En cours », le défaut, laisse
/// l'adresse nue.
class PayrollAdvancesLocation extends StatelessWidget {
  static const filterParam = 'filtre';
  static const defaultFilter = PayrollAdvanceFilter.ongoing;

  final Widget child;

  const PayrollAdvancesLocation({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<PayrollCubit, PayrollState, PayrollAdvanceFilter>(
        selector: (state) => state.advanceFilter,
        builder: (context, filter) => LocationParamsSync(
          current: {filterParam: filter == defaultFilter ? null : filter.name},
          onLocation: (read) => context.read<PayrollCubit>().setAdvanceFilter(
            PayrollAdvanceFilter.values
                    .where((value) => value.name == read[filterParam])
                    .firstOrNull ??
                defaultFilter,
          ),
          child: child,
        ),
      );
}
