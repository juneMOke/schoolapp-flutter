import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_page_helpers.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **La situation recherchée** — cinq segments, dont un seuil.
///
/// Les quatre premiers sont des catégories ; le cinquième, « A payé au
/// moins… », ouvre un champ. Il appartient à la même carte que le périmètre,
/// mais à un autre temps de la question : d'où le filet qui les sépare.
///
/// ## Le plancher exige une devise unique
///
/// En sélection mixte, le champ est **remplacé** par un avertissement qui donne
/// l'issue — ne garder qu'une devise. Comparer 50 000 FC à 120 $ n'a pas de
/// sens, et l'écran refuse de le simuler. Le segment reste sélectionnable : ce
/// n'est pas une faute de l'avoir choisi, c'est la sélection de frais qui doit
/// se resserrer.
///
/// ⚠️ Le tableau de bord voisin, lui, **accepte** un plancher en sélection
/// mixte et le dit « arbitrage ». Les deux écrans ne font pas la même chose du
/// résultat : là-bas on chiffre un ordre de grandeur, ici on nomme des élèves
/// qu'un parent signera. Nommer sur une conversion serait faire signer un
/// chiffre inventé.
class FeeControlSituationField extends StatelessWidget {
  final FeeControlPaymentFilter selected;

  /// Devise commune des frais retenus, `null` dès qu'ils en mêlent deux.
  final String? currency;

  final TextEditingController thresholdController;
  final bool enabled;
  final ValueChanged<FeeControlPaymentFilter> onChanged;
  final ValueChanged<String> onThresholdChanged;

  const FeeControlSituationField({
    super.key,
    required this.selected,
    required this.currency,
    required this.thresholdController,
    required this.enabled,
    required this.onChanged,
    required this.onThresholdChanged,
  });

  /// L'ordre des segments est celui de la question, pas celui de l'enum :
  /// « tous », puis du plus abîmé au plus en règle, puis le seuil.
  static const List<FeeControlPaymentFilter> order = [
    FeeControlPaymentFilter.all,
    FeeControlPaymentFilter.none,
    FeeControlPaymentFilter.partial,
    FeeControlPaymentFilter.settled,
    FeeControlPaymentFilter.threshold,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final symbol = currency == null ? '' : MoneyFormat.symbolOf(currency!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.feeControlSituationLabel, style: AppTextStyles.tableHeader),
        const SizedBox(height: AppDimensions.spacingS),
        SegmentedTabFilter<FeeControlPaymentFilter>(
          // Enroulé plutôt que comprimé : cinq segments ne tiennent pas sur une
          // ligne d'une tablette en portrait, et un libellé tronqué ferait lire
          // « Partiellement » pour « Partiellement payé ».
          wrap: true,
          enabled: enabled,
          selected: selected,
          semanticsLabel: l10n.feeControlSituationLabel,
          onSelected: onChanged,
          options: [
            for (final filter in order)
              SegmentedTabOption<FeeControlPaymentFilter>(
                value: filter,
                label: FeeControlPageHelpers.paymentFilterLabel(filter, l10n),
              ),
          ],
        ),
        if (selected.needsThreshold) ...[
          const SizedBox(height: AppDimensions.spacingS),
          if (currency == null)
            const _MixedWarning()
          else
            SizedBox(
              width: AppDimensions.recouvrementThresholdFieldWidth,
              child: CurrencyField(
                controller: thresholdController,
                currency: symbol,
                enabled: enabled,
                labelText: '${l10n.recouvrementThresholdLabel} ($symbol)',
                onChanged: onThresholdChanged,
              ),
            ),
        ],
      ],
    );
  }
}

/// Ce que l'écran refuse de faire, et ce qu'il faut faire à la place.
class _MixedWarning extends StatelessWidget {
  const _MixedWarning();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: const BoxConstraints(
        maxWidth: AppDimensions.recouvrementWarningMaxWidth,
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingS),
      decoration: BoxDecoration(
        color: AppColors.financeCrossedSurface,
        border: Border.all(color: AppColors.warning),
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
      ),
      child: Text(
        l10n.feeControlThresholdMixedWarning,
        style: AppTextStyles.caption,
      ),
    );
  }
}
