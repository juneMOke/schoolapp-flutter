import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Séparateur « OU » entre les deux groupes de recherche.
///
/// En mode [vertical] (mobile), une ligne horizontale traverse la pastille ;
/// sinon (wide), la pastille est simplement centrée entre les colonnes.
class SearchOrSeparator extends StatelessWidget {
  final String label;
  final bool vertical;

  const SearchOrSeparator({
    super.key,
    required this.label,
    this.vertical = true,
  });

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingXS + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTextStyles.badge.copyWith(color: AppColors.textMuted),
      ),
    );

    const line = Divider(color: AppColors.border, thickness: 1, height: 1);

    if (vertical) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
        child: Row(
          children: [
            const Expanded(child: line),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
              ),
              child: pill,
            ),
            const Expanded(child: line),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
      child: Center(child: pill),
    );
  }
}
