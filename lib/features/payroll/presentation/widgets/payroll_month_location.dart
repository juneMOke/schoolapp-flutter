import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';

/// Le mois ouvert tenu dans l'adresse : `?mois=2026-09`. F5 rouvre le même
/// mois, un lien partagé aussi, Précédent revient au mois d'avant. Le mois en
/// cours laisse l'adresse nue.
class PayrollMonthLocation extends StatelessWidget {
  static const monthParam = 'mois';

  final Widget child;

  const PayrollMonthLocation({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<PayrollCubit, PayrollState, String?>(
        selector: (state) => state.isCurrentMonth ? null : state.month,
        builder: (context, month) => LocationParamsSync(
          current: {monthParam: month},
          onLocation: (values) =>
              context.read<PayrollCubit>().showMonth(values[monthParam]),
          child: child,
        ),
      );
}
