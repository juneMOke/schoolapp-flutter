import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Pastille de synthèse posée dans [StudentDetailAppBar].
///
/// [alert] porte la lecture : une synthèse qui appelle une action (solde dû,
/// cas ouverts) se pose plus franchement qu'une synthèse rassurante.
class StudentDetailAppBarPill extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String label;
  final bool alert;

  const StudentDetailAppBarPill({
    super.key,
    required this.accent,
    required this.icon,
    required this.label,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingXS + 2,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: alert ? 0.20 : 0.26),
        borderRadius: AppRadius.brPill,
        border: Border.all(
          color: accent.withValues(alpha: alert ? 0.50 : 0.40),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textOnDark),
          const SizedBox(width: AppDimensions.spacingXS),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.textOnDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
