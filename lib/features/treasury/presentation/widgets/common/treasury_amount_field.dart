import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un montant de caisse : saisie libre (espaces et séparateurs tolérés), 0
/// accepté, la devise posée à droite du champ.
class TreasuryAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TreasuryCurrency currency;
  final bool enabled;
  final bool showError;
  final ValueChanged<String>? onChanged;

  const TreasuryAmountField({
    super.key,
    required this.controller,
    required this.label,
    required this.currency,
    this.enabled = true,
    this.showError = false,
    this.onChanged,
  });

  /// Les centimes lus, ou `null` si le champ ne dit pas un montant valable
  /// dans cette devise (illisible, ou centimes de franc).
  static int? read(String text, TreasuryCurrency currency) {
    final cents = AmountInput.toCentsOrZero(text);
    if (cents == null || !currency.acceptsCents(cents)) return null;
    return cents;
  }

  /// Le montant rangé, réécrit pour pré-remplir le champ (« 482000 »).
  static String formatForInput(int amountInCents) =>
      AmountInput.fromCents(amountInCents);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cents = AmountInput.toCentsOrZero(controller.text);
    final error = !showError
        ? null
        : cents == null
        ? l10n.treasuryAmountInvalid
        : !currency.acceptsCents(cents)
        ? l10n.treasuryAmountWholeFrancs
        : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: EteeloTextInput(
            controller: controller,
            label: label,
            required: true,
            enabled: enabled,
            keyboardType: EteeloTextInputType.number,
            capitalization: EteeloTextCapitalization.none,
            errorText: error,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Padding(
          // Aligné sur le champ, sous son libellé.
          padding: const EdgeInsets.only(top: AppSpacing.xl + AppSpacing.xs),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadius.brSm,
            ),
            child: Text(
              TreasuryFormat.symbol(currency),
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.bleuProfond,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
