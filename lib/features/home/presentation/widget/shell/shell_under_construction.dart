import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Écran d'un sous-menu que la coquille ne sait pas (encore) rendre.
class ShellUnderConstruction extends StatelessWidget {
  final String title;

  const ShellUnderConstruction({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: AppRadius.brMd,
        boxShadow: AppElevation.shadowCard,
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: AppDimensions.shellUnderConstructionIconSize,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              title,
              style: AppTextStyles.pageTitle.copyWith(
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              l10n.pageUnderConstruction,
              style: AppTextStyles.body.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
