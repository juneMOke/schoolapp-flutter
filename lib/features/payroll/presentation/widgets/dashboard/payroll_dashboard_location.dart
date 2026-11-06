import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/dashboard/payroll_dashboard_cubit.dart';

/// Le mois, le filtre et la devise du tableau de bord dans l'adresse :
/// `?mois=2026-09&filtre=reste&devise=USD` (la première devise servie
/// laisse la clé absente). F5 rouvre le même écran — et la même
/// requête, donc le même PDF. La recherche n'y va pas : chaque frappe serait
/// une entrée d'historique.
class PayrollDashboardLocation extends StatelessWidget {
  static const monthParam = 'mois';
  static const filterParam = 'filtre';
  static const currencyParam = 'devise';

  final Widget child;

  const PayrollDashboardLocation({super.key, required this.child});

  static (String?, String?, String?) _values(PayrollDashboardState state) => (
    state.isCurrentMonth ? null : state.month,
    state.filter.address,
    _currencyOf(state),
  );

  /// Les clés de [state] hors valeurs par défaut — ce que l'adresse du
  /// tableau de bord porte, devise comprise. Une fiche ouverte par-dessus
  /// les garde : après un F5 sur la fiche, le retour retrouve le même écran.
  static Map<String, String> queryOf(PayrollDashboardState state) {
    final (month, filter, currency) = _values(state);
    return {monthParam: ?month, filterParam: ?filter, currencyParam: ?currency};
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        PayrollDashboardCubit,
        PayrollDashboardState,
        (String?, String?, String?)
      >(
        selector: _values,
        builder: (context, values) => LocationParamsSync(
          current: {
            monthParam: values.$1,
            filterParam: values.$2,
            currencyParam: values.$3,
          },
          onLocation: (read) =>
              context.read<PayrollDashboardCubit>().applyLocation(
                month: read[monthParam],
                filter: PayrollDashboardFilter.fromAddress(read[filterParam]),
                currency: read[currencyParam],
              ),
          child: child,
        ),
      );

  /// La devise choisie, sauf la première servie — le défaut. Tant que le
  /// mois n'est pas lu, la devise demandée reste telle quelle.
  static String? _currencyOf(PayrollDashboardState state) {
    final currencies = state.dashboard?.currencies;
    if (currencies == null) return state.currency;
    return currencies.isNotEmpty && currencies.first.currency == state.currency
        ? null
        : state.currency;
  }
}
