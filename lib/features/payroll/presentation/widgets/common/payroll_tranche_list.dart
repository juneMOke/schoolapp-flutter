import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les versements reçus sur un salaire, dans l'ordre : n°, date, mode et
/// référence, montant, état d'envoi. Toucher une ligne l'ouvre.
class PayrollTrancheList extends StatelessWidget {
  final List<PayrollDisbursement> disbursements;
  final ValueChanged<PayrollDisbursement> onOpen;

  const PayrollTrancheList({
    super.key,
    required this.disbursements,
    required this.onOpen,
  });

  static String? _filled(String? text) =>
      text == null || text.trim().isEmpty ? null : text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, d) in disbursements.indexed)
          InkWell(
            onTap: () => onOpen(d),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpacing.xxxl),
              child: Row(
                children: [
                  Text(
                    l10n.payrollTrancheRank(index + 1),
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      [
                        PayrollLabels.day(context, d.paidAt),
                        PayrollLabels.mode(l10n, d.mode),
                        ?_filled(d.reference),
                      ].join(' · '),
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  Text(
                    MoneyFormat.format(d.amount),
                    style: AppTypography.labelLarge.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  RecordSyncDot(state: d.syncState),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
