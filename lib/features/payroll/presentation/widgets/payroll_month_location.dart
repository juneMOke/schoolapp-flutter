import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Le mois ouvert et les filtres du livre tenus dans l'adresse :
/// `?mois=2026-09&contrat=permanent&versement=unpaid`. F5 rouvre le même
/// mois, filtré pareil, un lien partagé aussi, Précédent revient au mois
/// d'avant. Le mois en cours et « tous » laissent l'adresse nue ; la
/// recherche n'y va pas.
class PayrollMonthLocation extends StatelessWidget {
  static const monthParam = 'mois';
  static const contractParam = 'contrat';
  static const payParam = 'versement';

  final Widget child;

  const PayrollMonthLocation({super.key, required this.child});

  static (String?, String?, String?) _values(PayrollState state) => (
    state.isCurrentMonth ? null : state.month,
    state.contractFilter?.name,
    state.payFilter == PayrollPayFilter.all ? null : state.payFilter.name,
  );

  /// Les clés de [state] hors valeurs par défaut — ce que l'adresse du livre
  /// porte. Une fiche ouverte par-dessus les garde : après un F5 sur la
  /// fiche, le retour retrouve le livre tel qu'il était.
  static Map<String, String> queryOf(PayrollState state) {
    final (month, contract, pay) = _values(state);
    return {monthParam: ?month, contractParam: ?contract, payParam: ?pay};
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<PayrollCubit, PayrollState, (String?, String?, String?)>(
        selector: _values,
        builder: (context, values) => LocationParamsSync(
          current: {
            monthParam: values.$1,
            contractParam: values.$2,
            payParam: values.$3,
          },
          onLocation: (read) => context.read<PayrollCubit>().applyLocation(
            month: read[monthParam],
            contract: StaffContractKind.values
                .where((kind) => kind.name == read[contractParam])
                .firstOrNull,
            payFilter:
                PayrollPayFilter.values
                    .where((filter) => filter.name == read[payParam])
                    .firstOrNull ??
                PayrollPayFilter.all,
          ),
          child: child,
        ),
      );
}
