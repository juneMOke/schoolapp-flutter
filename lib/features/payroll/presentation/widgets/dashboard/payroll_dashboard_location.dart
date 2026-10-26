import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/dashboard/payroll_dashboard_cubit.dart';

/// Le mois et le filtre du tableau de bord dans l'adresse :
/// `?mois=2026-09&filtre=reste`. F5 rouvre le même écran — et la même
/// requête, donc le même PDF. La recherche n'y va pas : chaque frappe serait
/// une entrée d'historique.
class PayrollDashboardLocation extends StatelessWidget {
  static const monthParam = 'mois';
  static const filterParam = 'filtre';

  final Widget child;

  const PayrollDashboardLocation({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        PayrollDashboardCubit,
        PayrollDashboardState,
        (String?, String?)
      >(
        selector: (state) =>
            (state.isCurrentMonth ? null : state.month, state.filter.address),
        builder: (context, values) => LocationParamsSync(
          current: {monthParam: values.$1, filterParam: values.$2},
          onLocation: (read) =>
              context.read<PayrollDashboardCubit>().applyLocation(
                month: read[monthParam],
                filter: PayrollDashboardFilter.fromAddress(read[filterParam]),
              ),
          child: child,
        ),
      );
}
