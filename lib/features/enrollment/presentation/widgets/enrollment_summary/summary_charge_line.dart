import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_designation.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SummaryChargeLine extends StatelessWidget {
  final StudentCharge charge;

  const SummaryChargeLine({super.key, required this.charge});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Même règle que l'étape « Frais » et que le guichet : le récapitulatif est
    // ce que le secrétariat relit avant de valider, il doit nommer les mêmes
    // lignes de la même façon.
    final label = chargeDesignation(charge, l10n);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            formatMonetaryAmountWithCurrency(
              amount: charge.expectedAmountInCents / 100,
              currency: charge.currency,
            ),
            textAlign: TextAlign.right,
            style: AppTextStyles.moneyTabular.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
