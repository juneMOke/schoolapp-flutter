import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// En-tête de la page « Mes cours » : médaillon + sur-titre + titre.
class MyCoursesHeader extends StatelessWidget {
  const MyCoursesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      header: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.bleuArdoiseSoft,
              borderRadius: AppRadius.brMd,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.bleuArdoise,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.myCoursesEyebrow.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.myCoursesTitle,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.bleuArdoise,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
