import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le libellé d'une section de formulaire : nom, « (optionnel) », compteur,
/// et une action alignée à droite. Partagé par la modale d'un chapitre et
/// l'éditeur du sujet d'une évaluation.
class FormSectionLabel extends StatelessWidget {
  final String label;
  final bool optional;
  final int count;
  final Widget? action;

  const FormSectionLabel({
    super.key,
    required this.label,
    this.optional = false,
    this.count = 0,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Flexible(
          child: Text.rich(
            TextSpan(
              text: label,
              children: [
                if (optional)
                  TextSpan(
                    text: ' ${l10n.formOptionalMark}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
            style: AppTypography.labelFormLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadius.brPill,
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '$count',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const Spacer(),
        ?action,
      ],
    );
  }
}
