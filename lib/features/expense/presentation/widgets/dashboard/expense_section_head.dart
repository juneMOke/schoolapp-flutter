import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// En-tête d'une section du tableau de bord : médaillon, titre, sous-titre.
class ExpenseSectionHead extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  /// Teinte du médaillon — **celle de la section**, et non un bleu unique.
  ///
  /// Les trois sections du tableau de bord portaient le même médaillon bleu,
  /// sans rapport avec leur contenu : l'évolution des dépenses, leur
  /// répartition et le classement des postes se ressemblaient là où leurs
  /// cartes vont désormais différer. Le défaut — bleu ardoise — garde le rendu
  /// d'avant pour tout appelant qui ne déclare rien.
  final Color accent;
  final Color accentSoft;

  const ExpenseSectionHead({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accent = AppColors.bleuArdoise,
    this.accentSoft = AppColors.bleuArdoiseSoft,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
    child: Row(
      children: [
        Container(
          width: AppDimensions.expenseInsightMedallionSize,
          height: AppDimensions.expenseInsightMedallionSize,
          decoration: BoxDecoration(
            color: accentSoft,
            borderRadius: BorderRadius.circular(
              AppDimensions.expenseIconBoxRadius,
            ),
          ),
          child: Icon(
            icon,
            size: AppDimensions.expenseMedallionIconSize,
            color: accent,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS + AppDimensions.spacingXS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyStrong),
              if (subtitle != null)
                Text(
                  subtitle!,
                  // `textMutedAa` : le gris muet ne tient que 3,69:1 sur du
                  // blanc, et moins encore sur un fond teinté.
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMutedAa,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
