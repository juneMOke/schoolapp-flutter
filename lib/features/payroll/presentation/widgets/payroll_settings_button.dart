import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dialogs/payroll_settings_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les réglages de paie de l'école — la direction seule (`hr.pay.manage`).
class PayrollSettingsButton extends StatelessWidget {
  const PayrollSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!PermissionGate.allows(context, kPayrollManageAccess.requires)) {
      return const SizedBox.shrink();
    }
    return IconButton(
      tooltip: AppLocalizations.of(context)!.payrollActionSettings,
      icon: const Icon(Icons.tune),
      onPressed: () async {
        final cubit = context.read<PayrollCubit>();
        final settings = await PayrollSettingsDialog.show(
          context,
          cubit.state.snapshot.settings,
        );
        if (settings == null || !context.mounted) return;
        await cubit.perform((commands) => commands.saveSettings(settings));
      },
    );
  }
}
