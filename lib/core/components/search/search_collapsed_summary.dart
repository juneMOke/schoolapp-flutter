import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/touch_target.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La recherche repliée, une fois lancée sur un téléphone : ses critères en
/// une ligne, et de quoi la rouvrir. Dépliée, la carte occupait ~500 dp et
/// les résultats commençaient sous le bas de l'écran.
class SearchCollapsedSummary extends StatelessWidget {
  /// Les critères envoyés, déjà mis en mots (« 6e A · Kabeya »).
  final String criteria;
  final VoidCallback onEdit;

  const SearchCollapsedSummary({
    super.key,
    required this.criteria,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Toute la ligne rouvre la carte : un bouton à libellé ne tenait pas à
    // côté des critères sur 360 dp, texte agrandi.
    return Semantics(
      button: true,
      label: l10n.searchCollapsedSemantics(criteria),
      hint: l10n.searchCollapsedEdit,
      excludeSemantics: true,
      child: InkWell(
        onTap: onEdit,
        borderRadius: AppRadius.brSm,
        child: TouchTarget(
          child: Row(
            children: [
              const Icon(
                Icons.manage_search_rounded,
                color: AppColors.bleuArdoise,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  criteria,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Tooltip(
                message: l10n.searchCollapsedEdit,
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.bleuArdoise,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
