import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Chip contextuel générique — icône + libellé avec un accent coloré.
///
/// Utilisé pour afficher des métadonnées compactes dans les sections
/// de détail finance (devise, date, montant, etc.).
class FinanceContextChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final Color accentSoft;

  const FinanceContextChip({
    super.key,
    required this.label,
    required this.icon,
    required this.accent,
    required this.accentSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: accentSoft,
        borderRadius: BorderRadius.circular(AppDimensions.spacingL),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.detailMiniIconSize, color: accent),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(label, style: AppTextStyles.badge.copyWith(color: accent)),
        ],
      ),
    );
  }
}
