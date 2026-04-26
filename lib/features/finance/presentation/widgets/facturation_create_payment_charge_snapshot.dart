import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_info_tile.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Affiche un instantané financier d'une charge (attendu / payé / restant / statut).
///
/// Utilisé deux fois dans [FacturationCreatePaymentAllocationItem] :
/// - avant paiement  → [accentColor] = charges accent (orange)
/// - après paiement  → [accentColor] = payments accent (violet)
class FacturationCreatePaymentChargeSnapshot extends StatelessWidget {
  final String title;
  final double expectedAmountInCents;
  final double amountPaidInCents;
  final String currency;
  final StudentChargeStatus status;
  final Color accentColor;
  final Color accentSoftColor;

  const FacturationCreatePaymentChargeSnapshot({
    super.key,
    required this.title,
    required this.expectedAmountInCents,
    required this.amountPaidInCents,
    required this.currency,
    required this.status,
    required this.accentColor,
    required this.accentSoftColor,
  });

  double get _remainingInCents => expectedAmountInCents - amountPaidInCents;

  String _fmt(double cents) {
    final major = (cents / 100).toStringAsFixed(2);
    final parts = major.split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
    return '$whole.${parts.last} $currency';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FinanceSectionCard(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      backgroundColor: accentSoftColor,
      borderColor: accentColor.withValues(alpha: 0.2),
      withShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinanceSectionHeader(
            icon: Icons.info_outline,
            title: title,
            accent: accentColor,
            accentSoft: accentColor.withValues(alpha: 0.15),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < AppDimensions.detailCompactBreakpoint;
              final tileWidth =
                  compact ? constraints.maxWidth : AppDimensions.detailInfoItemWidth;

              return Wrap(
                spacing: AppDimensions.spacingS,
                runSpacing: AppDimensions.spacingS,
                children: [
                  FinanceInfoTile(
                    width: tileWidth,
                    label: l10n.facturationCreatePaymentExpectedLabel,
                    value: _fmt(expectedAmountInCents),
                  ),
                  FinanceInfoTile(
                    width: tileWidth,
                    label: l10n.facturationCreatePaymentPaidLabel,
                    value: _fmt(amountPaidInCents),
                    backgroundColor: accentColor.withValues(alpha: 0.07),
                    borderColor: accentColor.withValues(alpha: 0.18),
                    valueColor: accentColor,
                  ),
                  FinanceInfoTile(
                    width: tileWidth,
                    label: l10n.facturationCreatePaymentRemainingLabel,
                    value: _fmt(_remainingInCents.clamp(0, double.infinity)),
                    backgroundColor: (_remainingInCents > 0
                            ? AppColors.warning
                            : AppColors.success)
                        .withValues(alpha: 0.07),
                    borderColor: (_remainingInCents > 0
                            ? AppColors.warning
                            : AppColors.success)
                        .withValues(alpha: 0.18),
                    valueColor:
                        _remainingInCents > 0 ? AppColors.warning : AppColors.success,
                  ),
                  FinanceInfoTile(
                    width: tileWidth,
                    label: l10n.facturationCreatePaymentStatusLabel,
                    value: status.localizedLabel(l10n),
                    backgroundColor: status.badgeColor.withValues(alpha: 0.07),
                    borderColor: status.badgeColor.withValues(alpha: 0.18),
                    valueColor: status.badgeColor,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
