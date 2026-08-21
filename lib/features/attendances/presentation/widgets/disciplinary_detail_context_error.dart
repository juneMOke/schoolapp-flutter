import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_detail_back_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Écran de repli de la fiche élève quand l'intent de navigation ne porte pas
/// de quoi afficher une identité (lien profond, reprise de session).
///
/// Extrait de la page pour la tenir sous la cible de taille ; le rendu est
/// inchangé.
class DisciplinaryDetailContextError extends StatelessWidget {
  const DisciplinaryDetailContextError({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPageBackground(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.report_problem_outlined,
              size: 40,
              color: AppColors.warning.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            l10n.disciplinaryDetailContextErrorTitle,
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            l10n.disciplinaryDetailContextErrorMessage,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          DisciplinaryDetailBackButton(
            label: l10n.disciplinaryDetailBackLabel,
            fallbackRoute: AppRoutesNames.presences,
          ),
        ],
      ),
    );
  }
}
