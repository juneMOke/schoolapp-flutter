import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_statement.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_actions.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_header.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_actions.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/statement/payroll_statement_table.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'état de paie du mois : le tableur que les écoles tiennent déjà, groupé
/// par catégorie, et la ligne de contrôle « brut − retenues = net » qui
/// remplace la vérification à l'œil.
class PayrollStatementTab extends StatelessWidget {
  final PayrollState state;

  const PayrollStatementTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final view = state.view;
    if (view == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final canWrite = PermissionGate.allows(
      context,
      kPayrollWriteAccess.requires,
    );
    final actions = PayrollLedgerActions(context);
    final groups = PayrollStatement.of(state.snapshot, view.lines);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            PayrollLedgerHeader(state: state, withCircuit: false),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                // L'état est composé par le serveur, sur la paie figée :
                // après validation seulement, en ligne (T16).
                if (view.phase.isLocked)
                  EteeloButton.secondary(
                    label: l10n.payrollStatementPrint,
                    icon: Icons.print_outlined,
                    onPressed: PayrollPayslipActions(context).openStatement,
                    fullWidth: false,
                  ),
                // Le recueil des bulletins : scellé, après validation (P8).
                if (view.phase.isLocked)
                  EteeloButton.ghost(
                    label: l10n.payrollPayslipAll,
                    icon: Icons.library_books_outlined,
                    onPressed: () =>
                        PayrollPayslipActions(context).openPdf(null),
                    fullWidth: false,
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (!view.isEditable)
          PayrollTone.draft.notice(
            l10n.payrollStatementLocked,
            icon: Icons.lock_outline,
          ),
        const SizedBox(height: AppSpacing.md),
        if (view.lines.isEmpty)
          EteeloEmptyResult(
            label: l10n.payrollEmptyStaff,
            medallionIcon: Icons.badge_outlined,
          )
        else ...[
          PayrollStatementTable(
            groups: groups,
            onOpen: (line) => view.isEditable && canWrite
                ? actions.editVariables(line)
                : context.read<PayrollCubit>().openPayslip(line.staffMemberId),
          ),
          const SizedBox(height: AppSpacing.md),
          _Control(lines: view.lines),
        ],
      ],
    );
  }
}

/// « brut − retenues = net », par devise : verte quand les colonnes se
/// recoupent, rouge sinon.
class _Control extends StatelessWidget {
  final List<PayrollLine> lines;

  const _Control({required this.lines});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencies = {for (final line in lines) line.currency}.toList()
      ..sort();
    final parts = <String>[];
    var consistent = true;
    for (final currency in currencies) {
      final of = lines.where((line) => line.currency == currency);
      final gross = of.fold(0, (sum, line) => sum + line.grossInCents);
      final withheld = of.fold(
        0,
        (sum, line) => sum + line.deductions.totalInCents + line.advanceInCents,
      );
      final net = of.fold(0, (sum, line) => sum + line.netInCents);
      if (gross - withheld != net) consistent = false;
      String money(int cents) => PayrollLabels.money(cents, currency);
      parts.add(
        l10n.payrollStatementControl(money(gross), money(withheld), money(net)),
      );
    }
    final tone = consistent ? PayrollTone.paid : PayrollTone.alert;
    return tone.notice(
      parts.join(' · '),
      icon: consistent ? Icons.check_circle_outline : Icons.error_outline,
    );
  }
}
