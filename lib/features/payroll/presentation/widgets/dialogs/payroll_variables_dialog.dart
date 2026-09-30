import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_net_banner.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_stepper.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les éléments variables d'un agent pour le mois : heures supplémentaires,
/// taux, enfants à charge. Le net se recalcule en direct, par le même moteur.
/// Rend les éléments à enregistrer, ou `null`.
class PayrollVariablesDialog extends StatefulWidget {
  final String name;
  final PayrollLine line;
  final PayrollVariables current;
  final PayrollSettings settings;

  /// La ligne qu'auraient ces éléments.
  final PayrollLine? Function(PayrollVariables variables) preview;

  const PayrollVariablesDialog({
    super.key,
    required this.name,
    required this.line,
    required this.current,
    required this.settings,
    required this.preview,
  });

  static Future<PayrollVariables?> show(
    BuildContext context,
    PayrollVariablesDialog dialog,
  ) => StaffDialog.show<PayrollVariables>(context, dialog);

  @override
  State<PayrollVariablesDialog> createState() => _PayrollVariablesDialogState();
}

class _PayrollVariablesDialogState extends State<PayrollVariablesDialog> {
  late int _overtime = widget.current.overtimeMinutes ?? 0;
  late int _children = widget.current.dependentChildren ?? widget.line.children;
  late final TextEditingController _rate = TextEditingController(
    text: widget.current.overtimeRateInCents == null
        ? ''
        : MoneyFormat.amountOnly(
            Money(widget.current.overtimeRateInCents!, widget.line.currency),
          ),
  );

  static const int _halfHour = 30;
  static const int _maxChildren = 12;

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  PayrollVariables get _variables => PayrollVariables(
    staffMemberId: widget.current.staffMemberId,
    overtimeMinutes: widget.line.overtimeAllowed && _overtime > 0
        ? _overtime
        : null,
    overtimeRateInCents: widget.line.overtimeAllowed
        ? AmountInput.toCents(_rate.text)
        : null,
    dependentChildren: _children,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final line = widget.line;
    final currency = line.currency;
    final preview = widget.preview(_variables) ?? line;
    final unit = widget.settings.of(currency).childAllowanceInCents;
    String money(int cents) => PayrollLabels.money(cents, currency);
    return StaffDialog(
      eyebrow: widget.name,
      title: l10n.payrollVarsTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Row(l10n.payrollVarsBase, money(preview.baseInCents)),
          const Divider(),
          Text(l10n.payrollVarsOvertime, style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          if (!line.overtimeAllowed)
            PayrollTone.draft.notice(l10n.payrollVarsNoOvertime)
          else ...[
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PayrollStepper(
                  value: _overtime,
                  step: _halfHour,
                  format: (minutes) => PayrollLabels.hours(l10n, minutes),
                  decreaseLabel: l10n.payrollDecrease,
                  increaseLabel: l10n.payrollIncrease,
                  onChanged: (value) => setState(() => _overtime = value),
                ),
                Text(
                  money(preview.overtimeInCents),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            EteeloTextInput(
              controller: _rate,
              label: l10n.payrollVarsRate,
              placeholder: l10n.payrollVarsRateHint(
                money(preview.overtimeRateInCents),
              ),
              keyboardType: EteeloTextInputType.number,
              capitalization: EteeloTextCapitalization.none,
              onChanged: (_) => setState(() {}),
            ),
          ],
          const Divider(),
          Text(l10n.payrollVarsChildren, style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PayrollStepper(
                value: _children,
                max: _maxChildren,
                format: (value) => '$value',
                decreaseLabel: l10n.payrollDecrease,
                increaseLabel: l10n.payrollIncrease,
                onChanged: (value) => setState(() => _children = value),
              ),
              Text(
                l10n.payrollVarsAllowance(
                  _children,
                  money(unit),
                  money(preview.allowanceInCents),
                ),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (preview.advances.isNotEmpty) ...[
            const Divider(),
            _Row(
              l10n.payrollVarsAdvances,
              '− ${money(preview.advanceInCents)}',
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          PayrollNetBanner(
            label: l10n.payrollColNet,
            amount: money(preview.netInCents),
          ),
        ],
      ),
      actions: [
        EteeloButton.ghost(
          label: l10n.payrollCancel,
          onPressed: () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: l10n.payrollSave,
          onPressed: () => Navigator.of(context).pop(_variables),
          fullWidth: false,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
          style: AppTypography.labelLarge.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}
