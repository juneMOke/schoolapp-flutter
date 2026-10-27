import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_refresh_shortcut.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/arrears/payroll_arrears_screen.dart';

/// RH · Paie ▸ Arriérés — le registre de la dette salariale, sur le même
/// cubit que la Paie (factory : un par page).
class PayrollArrearsPage extends StatelessWidget {
  const PayrollArrearsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<PayrollCubit>(
    create: (_) => getIt<PayrollCubit>()..load(),
    child: const PayrollRefreshShortcut(child: PayrollArrearsScreen()),
  );
}
