import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_rate.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_fee_options.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une créance de la fiche : le frais, sa devise, sa progression.
///
/// **Chaque ligne se solde dans sa propre devise** : il n'y a rien à convertir
/// ici, et donc rien qui dépende du cours du jour. Le taux affiché est celui de
/// cette créance-là — `(attendu − reste) / attendu`, la règle du module.
class FeeControlFeeLine extends StatelessWidget {
  final RecoveryChargePosition charge;

  /// Grille du niveau, pour nommer le frais comme l'école l'a écrit.
  final List<LocalFeeTariff> tariffs;

  /// Reçu pour homogénéité de signature ; inutilisé — une créance n'a qu'une
  /// devise, et son taux n'a donc jamais besoin d'un cours.
  final ExchangeRate? rate;

  const FeeControlFeeLine({
    super.key,
    required this.charge,
    required this.tariffs,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final expected = Money.parse(charge.expectedInCents, charge.currency);
    final paid = Money.parse(charge.paidTotalInCents, charge.currency);
    final remaining = Money.parse(charge.remainingInCents, charge.currency);
    final noExpectation = RecoveryRate.hasNoExpectation(charge.expectedInCents);
    final percent = RecoveryRate.of(
      expectedInCents: charge.expectedInCents,
      remainingInCents: charge.remainingInCents,
    );
    final label = feeControlFeeCodeLabel(
      feeControlFeeOptionFor(tariffs, charge.feeCode),
      charge.feeCode,
      l10n,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.bodyStrong)),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                MoneyFormat.symbolOf(charge.currency),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.spacingXS),
            child: LinearProgressIndicator(
              value: noExpectation ? 0 : percent / 100,
              minHeight: AppDimensions.recouvrementFeeLineBarHeight,
              backgroundColor: AppColors.border,
              // Trois teintes, celles des statuts : soldé, en cours, rien.
              // Une barre vide porte quand même la couleur de ce qu'elle dit.
              color: _barColor(percent, noExpectation),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Row(
            children: [
              Expanded(
                child: Text(
                  noExpectation
                      ? l10n.feeControlSheetNoExpectation
                      : l10n.feeControlSheetPaidOf(
                          MoneyFormat.format(paid),
                          MoneyFormat.format(expected),
                          percent,
                        ),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              // Le reste ne s'écrit que s'il en reste : « reste 0 $ » n'apprend
              // rien et brouille les lignes qui, elles, comptent.
              if (charge.remainingInCents > 0)
                Text(
                  l10n.feeControlSheetRemaining(MoneyFormat.format(remaining)),
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _barColor(int percent, bool noExpectation) {
    if (noExpectation) return AppColors.border;
    if (percent >= 100) return AppColors.vertSavane;
    return percent > 0 ? AppColors.orDoux : AppColors.error;
  }
}
