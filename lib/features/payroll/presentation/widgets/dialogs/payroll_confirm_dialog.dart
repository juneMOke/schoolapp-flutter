import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_fingerprint.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Confirmer une soumission ou une validation : ce qui part, devise par
/// devise — agents, masse brute, avances, net. Rend `true` pour confirmer.
class PayrollConfirmDialog extends StatelessWidget {
  final PayrollMonthView view;
  final String title;
  final String confirmLabel;
  final String? warning;

  const PayrollConfirmDialog({
    super.key,
    required this.view,
    required this.title,
    required this.confirmLabel,
    this.warning,
  });

  static Future<bool> show(
    BuildContext context, {
    required PayrollMonthView view,
    required String title,
    required String confirmLabel,
    String? warning,
  }) async =>
      await StaffDialog.show<bool>(
        context,
        PayrollConfirmDialog(
          view: view,
          title: title,
          confirmLabel: confirmLabel,
          warning: warning,
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final warning = this.warning;
    return StaffDialog(
      title: title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Line(l10n.payrollColAgent, l10n.payrollKpiAgents(view.lines.length)),
          _Line(
            l10n.payrollKpiGross,
            _join(view.totals, (t) => t.grossInCents),
          ),
          _Line(
            l10n.payrollKpiAdvances,
            _join(view.totals, (t) => t.advanceInCents),
          ),
          _Line(
            l10n.payrollKpiNet,
            _join(view.totals, (t) => t.netInCents),
            strong: true,
          ),
          if (warning != null) ...[
            const SizedBox(height: AppSpacing.md),
            PayrollTone.submitted.notice(
              warning,
              icon: Icons.warning_amber_rounded,
            ),
          ],
        ],
      ),
      actions: [
        EteeloButton.ghost(
          label: l10n.payrollCancel,
          onPressed: () => Navigator.of(context).pop(false),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: confirmLabel,
          onPressed: () => Navigator.of(context).pop(true),
          fullWidth: false,
        ),
      ],
    );
  }

  static String _join(
    List<PayrollTotal> totals,
    int Function(PayrollTotal total) amountOf,
  ) => PayrollLabels.perCurrency(
    totals.map((total) => (amountOf(total), total.currency)),
  ).join(' · ');
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _Line(this.label, this.value, {this.strong = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: (strong ? AppTypography.titleMedium : AppTypography.bodyMedium)
              .copyWith(
                color: AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
      ],
    ),
  );
}
