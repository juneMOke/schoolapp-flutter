import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_reason.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/payment_correction/payment_correction_reason_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// En tête de la page de correction : le versement d'origine, barré, qui va
/// être annulé.
class FacturationPaymentCorrectionOriginCard extends StatelessWidget {
  final MoneyBag amounts;
  final DateTime paidAt;

  const FacturationPaymentCorrectionOriginCard({
    super.key,
    required this.amounts,
    required this.paidAt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final struck = AppTextStyles.bodyStrong.copyWith(
      color: AppColors.textMuted,
      decoration: TextDecoration.lineThrough,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.06),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paymentCorrectionOriginLabel,
            style: AppTextStyles.caption.copyWith(color: AppColors.danger),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Row(
            children: [
              Expanded(
                child: Text(
                  MaterialLocalizations.of(context).formatShortDate(paidAt),
                  style: struck,
                ),
              ),
              Text(
                amounts.entries.map(MoneyFormat.format).join(' · '),
                style: struck,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Au pied de la page de correction : le motif, l'écart avec l'origine, et
/// pourquoi le bouton reste éteint quand rien n'a changé.
class FacturationPaymentCorrectionReasonCard extends StatelessWidget {
  final PaymentCorrectionReason? reason;
  final ValueChanged<PaymentCorrectionReason> onReasonSelected;
  final TextEditingController detailController;
  final bool cashMoved;
  final ValueChanged<bool> onCashMovedChanged;

  /// L'écart avec l'origine, déjà rendu (« −100,00 $ »), `null` s'il est nul.
  /// Neutre (D8) : une faute de frappe ne déplace pas d'argent.
  final String? gapLabel;

  /// Rien n'a changé par rapport à l'origine.
  final bool unchanged;

  /// Le refus local, déjà rendu, s'il y en a un.
  final String? failure;

  final bool enabled;

  const FacturationPaymentCorrectionReasonCard({
    super.key,
    required this.reason,
    required this.onReasonSelected,
    required this.detailController,
    required this.cashMoved,
    required this.onCashMovedChanged,
    this.gapLabel,
    this.unchanged = false,
    this.failure,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FinanceSectionCard(
      backgroundColor: AppColors.surfaceRaised,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (gapLabel case final gap?) ...[
            Text(
              l10n.paymentCorrectionGap(gap),
              key: const ValueKey('payment-correction-gap'),
              style: AppTextStyles.bodyStrong.copyWith(color: AppColors.info),
            ),
            const SizedBox(height: AppDimensions.spacingM),
          ],
          PaymentCorrectionReasonSection(
            gesture: PaymentCorrectionGesture.replace,
            selected: reason,
            onSelected: onReasonSelected,
            detailController: detailController,
            cashMoved: cashMoved,
            onCashMovedChanged: onCashMovedChanged,
            enabled: enabled,
          ),
          if (unchanged)
            Text(
              l10n.paymentCorrectionNoChange,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          if (failure case final message?)
            Padding(
              padding: const EdgeInsets.only(top: AppDimensions.spacingS),
              child: Text(
                l10n.paymentCorrectionFailed(message),
                style: AppTextStyles.body.copyWith(color: AppColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}
