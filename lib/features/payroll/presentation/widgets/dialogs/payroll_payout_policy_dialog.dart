import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_payout_preview.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_circuit_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_amount_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le taux choisi et son motif.
typedef PayrollPayoutChoice = ({int rate, String? reason});

/// « Quelle part du net verser ce mois ? » — le taux de versement du mois,
/// son motif (requis sous 100 %), et l'aperçu de ce qu'il donnerait. Rend le
/// choix, ou `null`.
class PayrollPayoutPolicyDialog extends StatefulWidget {
  final String monthLabel;
  final List<PayrollLine> lines;
  final int rate;
  final String? reason;

  const PayrollPayoutPolicyDialog({
    super.key,
    required this.monthLabel,
    required this.lines,
    required this.rate,
    this.reason,
  });

  static Future<PayrollPayoutChoice?> show(
    BuildContext context,
    PayrollPayoutPolicyDialog dialog,
  ) => EteeloFormDialog.show<PayrollPayoutChoice>(context, dialog);

  @override
  State<PayrollPayoutPolicyDialog> createState() =>
      _PayrollPayoutPolicyDialogState();
}

class _PayrollPayoutPolicyDialogState extends State<PayrollPayoutPolicyDialog> {
  static const List<int> _presets = [100, 75, 60, 50];

  late int _rate = widget.rate;
  late final TextEditingController _other = TextEditingController(
    text: _presets.contains(widget.rate) ? '' : '${widget.rate}',
  );
  late final TextEditingController _reason = TextEditingController(
    text: widget.reason ?? '',
  );

  @override
  void dispose() {
    _other.dispose();
    _reason.dispose();
    super.dispose();
  }

  bool get _complete =>
      _rate >= 100 || _reason.text.trim().length >= minPayoutReasonLength;

  void _typed(String text) {
    final value = int.tryParse(text.trim());
    if (value != null && value >= 0 && value <= 100) {
      setState(() => _rate = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totals = PayrollPayoutPreview.at(widget.lines, _rate);
    String join(int Function(PayrollPayoutTotals t) of) =>
        totals.map((t) => PayrollLabels.money(of(t), t.currency)).join(' · ');
    void submit() {
      if (!_complete) return;
      Navigator.of(
        context,
      ).pop((rate: _rate, reason: _rate >= 100 ? null : _reason.text.trim()));
    }

    return EteeloFormDialog(
      onSubmit: submit,
      eyebrow: l10n.payrollPayoutEyebrow(widget.monthLabel),
      title: l10n.payrollPayoutTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final preset in _presets)
                EteeloFilterChip(
                  label: l10n.payrollPayoutRate(preset),
                  selected: _rate == preset,
                  color: AppColors.terreCuite,
                  soft: AppColors.terreCuiteSoft,
                  ink: AppColors.terreCuiteDark,
                  onTap: () => setState(() {
                    _rate = preset;
                    _other.clear();
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          EteeloTextInput(
            controller: _other,
            label: l10n.payrollPayoutOther,
            keyboardType: EteeloTextInputType.number,
            capitalization: EteeloTextCapitalization.none,
            onChanged: _typed,
          ),
          if (_rate < 100) ...[
            const SizedBox(height: AppSpacing.sm),
            EteeloTextInput(
              controller: _reason,
              label: l10n.payrollPayoutReason,
              required: true,
              keyboardType: EteeloTextInputType.multiline,
              minLines: 2,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          PayrollAmountRow(l10n.payrollPayoutDue, join((t) => t.dueInCents)),
          PayrollAmountRow(
            l10n.payrollPayoutToPay,
            join((t) => t.toPayInCents),
            ink: PayrollTone.paid.ink,
          ),
          PayrollAmountRow(
            l10n.payrollPayoutDeferred,
            join((t) => t.deferredInCents),
            ink: PayrollTone.submitted.ink,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.payrollPayoutFixedKept,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
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
          label: l10n.payrollPayoutApply(_rate),
          onPressed: _complete ? submit : null,
          fullWidth: false,
        ),
      ],
    );
  }
}
