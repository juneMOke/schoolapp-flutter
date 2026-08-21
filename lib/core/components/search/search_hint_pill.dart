import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Bandeau d'aide d'un formulaire de recherche : icône + texte explicatif.
///
/// Partagé par l'aide de mode de [SearchModeSwitch] et par la pastille propre à
/// une feature (« ces élèves viennent de l'année précédente »), pour que les
/// deux se ressemblent au lieu de se concurrencer.
class SearchHintPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const SearchHintPill({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.bleuArdoise.withValues(alpha: 0.06),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.bleuArdoise.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.bleuArdoise),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
