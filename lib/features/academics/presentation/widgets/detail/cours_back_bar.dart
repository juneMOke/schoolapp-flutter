import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Fil de retour de la page détail (spec § Anatomie) : bouton « Mes cours » +
/// fil d'Ariane « Mes cours › {branche} · {classe} ». Reste visible dans tous
/// les états (y compris erreur).
class CoursBackBar extends StatelessWidget {
  final String brancheNom;
  final String classroomName;
  final VoidCallback onBack;

  const CoursBackBar({
    super.key,
    required this.brancheNom,
    required this.classroomName,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final crumbLast = '$brancheNom · $classroomName';

    // Le bouton de retour porte déjà « Mes cours » : le fil d'Ariane n'affiche
    // donc que le cran courant (branche · classe) pour éviter la redite.
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _BackButton(label: l10n.courseDetailBackToCourses, onTap: onBack),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            crumbLast,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BackButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.brPill,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minTouchTarget,
            ),
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              right: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: AppRadius.brPill,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: AppColors.bleuArdoise,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.bleuArdoise,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
