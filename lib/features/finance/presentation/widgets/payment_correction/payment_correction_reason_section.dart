import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_reason.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/payment_correction_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Motif d'une correction : liste fermée filtrée selon le geste, précision
/// libre (obligatoire pour « Autre »), et la confirmation que de l'argent a
/// vraiment changé de main (D8).
///
/// Contrôlée : l'état vit chez l'appelant, qui décide aussi du bouton.
class PaymentCorrectionReasonSection extends StatelessWidget {
  final PaymentCorrectionGesture gesture;
  final PaymentCorrectionReason? selected;
  final ValueChanged<PaymentCorrectionReason> onSelected;
  final TextEditingController detailController;
  final bool cashMoved;
  final ValueChanged<bool> onCashMovedChanged;
  final bool enabled;

  /// Motifs retirés de la liste du geste — un motif que l'écran ne sait pas
  /// honorer ne se propose pas.
  final Set<PaymentCorrectionReason> excluded;

  const PaymentCorrectionReasonSection({
    super.key,
    required this.gesture,
    required this.selected,
    required this.onSelected,
    required this.detailController,
    required this.cashMoved,
    required this.onCashMovedChanged,
    this.enabled = true,
    this.excluded = const {},
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detailRequired = selected?.requiresDetail ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.paymentCorrectionReasonLabel,
          style: AppTextStyles.bodyStrong.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingS,
          children: [
            for (final reason in PaymentCorrectionReason.forGesture(gesture))
              if (!excluded.contains(reason))
                ChoiceChip(
                  key: ValueKey('payment-correction-reason-${reason.code}'),
                  label: Text(paymentCorrectionReasonLabel(reason, l10n)),
                  selected: reason == selected,
                  onSelected: enabled ? (_) => onSelected(reason) : null,
                  selectedColor: AppColors.info.withValues(alpha: 0.14),
                  side: BorderSide(
                    color: reason == selected
                        ? AppColors.info
                        : AppColors.border,
                  ),
                  labelStyle: AppTextStyles.body.copyWith(
                    color: reason == selected
                        ? AppColors.info
                        : AppColors.textPrimary,
                    fontWeight: reason == selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        EteeloTextInput(
          key: const ValueKey('payment-correction-detail'),
          controller: detailController,
          label: detailRequired
              ? l10n.paymentCorrectionDetailRequiredLabel
              : l10n.paymentCorrectionDetailLabel,
          required: detailRequired,
          keyboardType: EteeloTextInputType.multiline,
          minLines: 1,
          maxLines: 3,
          readOnly: !enabled,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        CheckboxListTile(
          key: const ValueKey('payment-correction-cash-moved'),
          value: cashMoved,
          onChanged: enabled ? (v) => onCashMovedChanged(v ?? false) : null,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            l10n.paymentCorrectionCashMovedLabel,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
          subtitle: Text(
            l10n.paymentCorrectionCashMovedHint,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
