import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le taux appliqué à une paire de devises sur ce versement.
class FacturationRatePair {
  /// Le taux réellement appliqué — celui du caissier s'il l'a corrigé.
  final ExchangeRate rate;

  /// Celui que l'école a paramétré, second terme du contrôle de divergence.
  final ExchangeRate? referenceRate;

  final TextEditingController controller;
  final bool editing;
  final VoidCallback onEdit;

  /// Le taux saisi sort de la bande paramétrée par l'école.
  final bool diverges;

  const FacturationRatePair({
    required this.rate,
    required this.referenceRate,
    required this.controller,
    required this.editing,
    required this.onEdit,
    required this.diverges,
  });
}

/// Le taux du jour — **une ligne par paire réellement utilisée**.
///
/// ## Pourquoi le taux est ici et la devise sur la ligne de frais
///
/// La devise se choisit frais par frais, parce que c'est là que la question se
/// pose. Le taux, lui, ne se choisit pas : il est le même pour toutes les
/// lignes d'une même paire, et le corriger à deux endroits ferait deux taux
/// pour un seul versement — que le modèle refuse d'écrire.
///
/// ## Le guichet propose, le caissier n'invente pas
///
/// Le taux arrive rempli depuis le référentiel, en lecture. Le corriger demande
/// un geste explicite. Au-delà de la bande paramétrée par l'école, un
/// avertissement s'affiche **sans rien bloquer** : l'argent est sur le
/// comptoir, on signale, on ne refuse pas. Mais on le signale ici, où il se
/// corrige encore devant le parent — après le versement, l'arbitrage ne fait
/// plus que constater.
class TenderSettlementSection extends StatelessWidget {
  /// Les paires converties sur ce versement. Vide ⇒ rien à afficher.
  final List<FacturationRatePair> pairs;

  final bool enabled;

  /// Dire, plutôt que de disparaître, quand aucun taux n'est paramétré.
  ///
  /// Faux tant qu'aucun frais n'est coché : il n'y a alors pas de question à
  /// poser, et une mention sur un formulaire vide serait du bruit.
  final bool explainWhenUnavailable;

  const TenderSettlementSection({
    super.key,
    this.pairs = const [],
    this.enabled = true,
    this.explainWhenUnavailable = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Aucune conversion en cours. Éteindre la section en silence laisserait un
    // écran où il ne se passe RIEN, et rien ne distinguerait « cette école
    // n'encaisse qu'en une monnaie » de « la fonction est cassée ». On dit donc
    // ce qui manque — mais seulement quand la question se pose.
    if (pairs.isEmpty) {
      if (!explainWhenUnavailable) return const SizedBox.shrink();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.currency_exchange_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Expanded(
            child: Text(
              l10n.facturationSettlementNoRate,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < pairs.length; i++) ...[
          _RateRow(pair: pairs[i], enabled: enabled),
          if (i < pairs.length - 1)
            const SizedBox(height: AppDimensions.spacingS),
        ],
      ],
    );
  }
}

class _RateRow extends StatelessWidget {
  final FacturationRatePair pair;
  final bool enabled;

  const _RateRow({required this.pair, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rate = pair.rate;
    final hint = l10n.facturationSettlementRateHint(
      MoneyFormat.symbolOf(rate.quote),
      MoneyFormat.symbolOf(rate.base),
    );

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.orDoux.withValues(alpha: 0.08),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.orDoux.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pair.editing)
            CurrencyField(
              controller: pair.controller,
              currency: hint,
              enabled: enabled,
              labelText: l10n.facturationSettlementRateFieldLabel,
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.facturationSettlementRateLabel.toUpperCase(),
                        style: AppTextStyles.badge.copyWith(
                          color: AppColors.textMuted,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        '${rate.formatted()} $hint',
                        style: AppTextStyles.moneyTabular.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: enabled ? pair.onEdit : null,
                  child: Text(l10n.facturationSettlementRateEdit),
                ),
              ],
            ),
          if (pair.diverges && pair.referenceRate != null) ...[
            const SizedBox(height: AppDimensions.spacingXS),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppDimensions.spacingXS),
                Expanded(
                  child: Text(
                    l10n.facturationSettlementRateDiverges(
                      pair.referenceRate!.formatted(),
                    ),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
