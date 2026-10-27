import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_payout_policy.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_payout_preview.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_callout.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La politique de versement du mois, sous le geste du mois : « ce mois,
/// l'école verse 60 % du net · 2 agents en versement réduit ». Neutre (et
/// réservée à l'économe en brouillon, en pointillé) tant que tout le net est
/// versé.
class PayrollPayoutBar extends StatelessWidget {
  final PayrollMonthView view;
  final bool canEdit;
  final VoidCallback onEdit;

  const PayrollPayoutBar({
    super.key,
    required this.view,
    required this.canEdit,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final active = view.hasReducedPayout;
    if (!active && !canEdit) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final rate = view.payoutPolicy?.ratePercent ?? PayrollPayoutPolicy.full;
    final reason = view.payoutPolicy?.reason;
    final totals = PayrollPayoutPreview.at(view.lines, rate);
    String join(int Function(PayrollPayoutTotals t) of) =>
        totals.map((t) => PayrollLabels.money(of(t), t.currency)).join(' · ');
    final reduced = PayrollPayoutPreview.reducedCount(view.lines);
    return PayrollCallout(
      icon: Icons.percent,
      kind: active ? PayrollCalloutKind.tinted : PayrollCalloutKind.dashed,
      tone: PayrollTone.submitted,
      title: active
          ? l10n.payrollPayoutBarActive(rate, reduced)
          : l10n.payrollPayoutBarFull,
      details: active
          ? [
              l10n.payrollPayoutBarDetail(
                join((t) => t.toPayInCents),
                join((t) => t.dueInCents),
                join((t) => t.deferredInCents),
              ),
              if (reason != null && reason.isNotEmpty)
                l10n.payrollPayoutBarReason(reason),
            ]
          : [l10n.payrollPayoutBarFullDetail],
      action: canEdit
          ? EteeloButton.secondary(
              label: active
                  ? l10n.payrollPayoutBarEdit
                  : l10n.payrollPayoutBarSet,
              icon: Icons.percent,
              onPressed: onEdit,
              fullWidth: false,
            )
          : null,
    );
  }
}
